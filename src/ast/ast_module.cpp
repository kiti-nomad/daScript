#include "daScript/misc/platform.h"

#include "daScript/ast/ast.h"

namespace das
{
    // ANNOTATION

    const AnnotationArgument * AnnotationArgumentList::find ( const string & name, Type type ) const {
        auto it = find_if(arguments.begin(), arguments.end(), [&](const AnnotationArgument & arg){
            return (arg.name==name) && (type==Type::tVoid || type==arg.type);
        });
        return it==arguments.end() ? nullptr : &*it;
    }

    bool AnnotationArgumentList::getOption(const string & name, bool def) const {
        auto arg = find(name, Type::tBool);
        return arg ? arg->bValue : def;
    }

    // MODULE

    intptr_t Module::Karma = 0;
    Module * Module::modules = nullptr;

    void Module::Shutdown() {
        auto m = modules;
        while ( m ) {
            auto pM = m;
            m = m->next;
            delete pM;
        }
    }

    Module * Module::require ( const string & name ) {
        for ( auto m = modules; m != nullptr; m = m->next ) {
            if ( m->name == name ) {
                return m;
            }
        }
        return nullptr;
    }

    Module::Module ( const string & n ) : name(n) {
        if ( !name.empty() ) {
            next = modules;
            modules = this;
        }
    }

    Module::~Module() {
        if ( !name.empty() ) {
            Module ** p = &modules;
            for ( auto m = modules; m != nullptr; p = &m->next, m = m->next ) {
                if ( m == this ) {
                    *p = m->next;
                    return;
                }
            }
            assert(0 && "failed to unlink");
        }
    }

    bool Module::addAnnotation ( const AnnotationPtr & ptr ) {
        if ( handleTypes.insert(make_pair(ptr->name, move(ptr))).second ) {
            ptr->seal(this);
            return true;
        } else {
            return false;
        }
    }

    bool Module::addVariable ( const VariablePtr & var ) {
        if ( globals.insert(make_pair(var->name, var)).second ) {
            var->module = this;
            return true;
        } else {
            return false;
        }
    }

    bool Module::addEnumeration ( const EnumerationPtr & en ) {
        if ( enumerations.insert(make_pair(en->name, en)).second ) {
            en->module = this;
            return true;
        } else {
            return false;
        }
    }

    bool Module::addStructure ( const StructurePtr & st ) {
        if ( structures.insert(make_pair(st->name, st)).second ) {
            st->module = this;
            return true;
        } else {
            return false;
        }
    }

    bool Module::addFunction ( const FunctionPtr & fn ) {
        auto mangledName = fn->getMangledName();
        if ( functions.insert(make_pair(mangledName, fn)).second ) {
            functionsByName[fn->name].push_back(fn);
            fn->module = this;
            return true;
        } else {
            // assert(0 && "can't add function");
            return false;
        }
    }

    bool Module::addGeneric ( const FunctionPtr & fn ) {
        auto mangledName = fn->getMangledName();
        if ( generics.insert(make_pair(mangledName, fn)).second ) {
            genericsByName[fn->name].push_back(fn);
            fn->module = this;
            return true;
        } else {
            // assert(0 && "can't add function");
            return false;
        }
    }

    VariablePtr Module::findVariable ( const string & na ) const {
        auto it = globals.find(na);
        return it != globals.end() ? it->second : VariablePtr();
    }

    FunctionPtr Module::findFunction ( const string & mangledName ) const {
        auto it = functions.find(mangledName);
        return it != functions.end() ? it->second : FunctionPtr();
    }

    StructurePtr Module::findStructure ( const string & na ) const {
        auto it = structures.find(na);
        return it != structures.end() ? it->second : StructurePtr();
    }

    AnnotationPtr Module::findAnnotation ( const string & na ) const {
        auto it = handleTypes.find(na);
        return it != handleTypes.end() ? it->second : nullptr;
    }

    EnumerationPtr Module::findEnum ( const string & na ) const {
        auto it = enumerations.find(na);
        return it != enumerations.end() ? it->second : nullptr;
    }

    ExprCallFactory * Module::findCall ( const string & na ) const {
        auto it = callThis.find(na);
        return it != callThis.end() ? &it->second : nullptr;
    }

    bool Module::compileBuiltinModule ( unsigned char * str, unsigned int str_len ) {
        TextWriter issues;
        str[str_len-1] = 0;//replace last symbol with null terminating. fixme: This is sloppy, and assumes there is something to replace!
        if (auto program = parseDaScript((const char*)str, issues)) {
            if (program->failed()) {
#if 1
                for (auto & err : program->errors) {
                    issues << reportError((const char*)str, err.at.line, err.at.column, err.what, err.cerr);
                }
                printf("%s\n", issues.str().c_str());
#endif
                assert(0 && "this happens when builtin module does not compile");
                return false;
            }
            // ok, now let's rip content
            for (auto & gen : program->thisModule->generics) {
                addGeneric(gen.second);
            }
            for (auto & glob : program->thisModule->globals) {
                addVariable(glob.second);
            }
            for (auto & fun : program->thisModule->functions) {
                addFunction(fun.second);
            }
            return true;
        } else {
            assert(0 && "this happens when builtin module does not parse");
            return false;
        }
    }


    // MODULE LIBRARY

    bool splitTypeName ( const string & name, string & moduleName, string & funcName ) {
        auto at = name.find("::");
        if ( at!=string::npos ) {
            moduleName = name.substr(0,at);
            funcName = name.substr(at+2);
            return true;
        } else {
            moduleName = "*";
            funcName = name;
            return false;
        }
    }

    void ModuleLibrary::addBuiltInModule () {
        addModule(Module::require("$"));
    }

    void ModuleLibrary::addModule ( Module * module ) {
        assert(module && "module not found? or you have forgot to NEED_MODULE(Module_BuiltIn) be called first");
        modules.push_back(module);
    }

    void ModuleLibrary::foreach ( function<bool (Module * module)> && func, const string & moduleName ) const {
        bool any = moduleName=="*";
        for ( auto pm : modules ) {
            if ( !any && pm->name!=moduleName ) continue;
            if ( !func(pm) ) break;
        }
    }

    vector<AnnotationPtr> ModuleLibrary::findAnnotation ( const string & name ) const {
        vector<AnnotationPtr> ptr;
        string moduleName, annName;
        splitTypeName(name, moduleName, annName);
        foreach([&](Module * pm) -> bool {
            if ( auto pp = pm->findAnnotation(annName) )
                ptr.push_back(pp);
            return true;
        }, moduleName);
        return ptr;
    }

    vector<StructurePtr> ModuleLibrary::findStructure ( const string & name ) const {
        vector<StructurePtr> ptr;
        string moduleName, funcName;
        splitTypeName(name, moduleName, funcName);
        foreach([&](Module * pm) -> bool {
            if ( auto pp = pm->findStructure(funcName) )
                ptr.push_back(pp);
            return true;
        }, moduleName);
        return ptr;
    }

    vector<EnumerationPtr> ModuleLibrary::findEnum ( const string & name ) const {
        vector<EnumerationPtr> ptr;
        string moduleName, enumName;
        splitTypeName(name, moduleName, enumName);
        foreach([&](Module * pm) -> bool {
            if ( auto pp = pm->findEnum(enumName) )
                ptr.push_back(pp);
            return true;
        }, moduleName);
        return ptr;
    }

    TypeDeclPtr ModuleLibrary::makeStructureType ( const string & name ) const {
        auto t = make_shared<TypeDecl>(Type::tStructure);
        auto structs = findStructure(name);
        if ( structs.size()==1 ) {
            t->structType = structs.back();
        } else {
            assert(0 && "can't make structure type");
        }
        return t;
    }

    TypeDeclPtr ModuleLibrary::makeHandleType ( const string & name ) const {
        auto t = make_shared<TypeDecl>(Type::tHandle);
        auto handles = findAnnotation(name);
        if ( handles.size()==1 ) {
            if ( handles.back()->rtti_isHandledTypeAnnotation() ) {
                t->annotation = static_pointer_cast<TypeAnnotation>(handles.back());
            } else {
                assert(0 && "can't make handle type");
                return nullptr;
            }
        } else {
            assert(0 && "can't make handle type");
            return nullptr;
        }
        return t;
    }

    TypeDeclPtr ModuleLibrary::makeEnumType ( const string & name ) const {
        auto t = make_shared<TypeDecl>(Type::tEnumeration);
        auto enums = findEnum(name);
        if ( enums.size()==1 ) {
            t->enumType = enums.back();
        } else {
            assert(0 && "can't make enumeration type");
        }
        return t;
    }
}

