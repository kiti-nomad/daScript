options indenting=4
options remove_unused_symbols=false

let
    print_flags_debugger = (
            print_flags escapeString
        |   print_flags namesAndDimensions
        |   print_flags humanReadable
        |   print_flags typeQualifiers
        |   print_flags refAddresses
    )

[generic]
def intptr ( p : void? ) : uint64
	static_if typeinfo(sizeof p)==4
        unsafe
		    return uint64(reinterpret<uint> p)
	else
        unsafe
		    return reinterpret<uint64> p

def resize(var Arr:array<auto(numT)>;newSize:int)
    __builtin_array_resize(Arr,newSize,typeinfo(sizeof type<numT>))

def reserve(var Arr:array<auto(numT)>;newSize:int)
    __builtin_array_reserve(Arr,newSize,typeinfo(sizeof type<numT>))

def push(var Arr:array<auto(numT)>;value:numT const;at:int=-1)
    static_if typeinfo(can_copy value)
        Arr[__builtin_array_push(Arr,at,typeinfo(sizeof type<numT>))] = value
    else
        concept_assert(false,"can't push value, which can't be copied")

def pop(var Arr:array<auto(numT)>)
    resize(Arr, length(Arr)-1)  // resize will throw if negative

def emplace(var Arr:array<auto(numT)>;var value:numT;at:int=-1)
    static_if typeinfo(can_move value)
        Arr[__builtin_array_push(Arr,at,typeinfo(sizeof type<numT>))] <- value
    else
        concept_assert(false,"can't emplace value, which can't be moved")

def push_clone(var Arr:array<auto(numT)>;value:numT;at:int=-1)
    static_if typeinfo(can_clone value)
        Arr[__builtin_array_push_zero(Arr,at,typeinfo(sizeof type<numT>))] := value
    else
        concept_assert(false,"can't push-clone value, which can't be moved")

def erase(var Arr:array<auto(numT)>;at:int)
    __builtin_array_erase(Arr,at,typeinfo(sizeof type<numT>))

[unused_argument(a)]
def length(a:auto[]):int
    return typeinfo(dim a)

// table

def find(Tab:table<auto(keyT);auto(valT)>;at:keyT;blk:block<(p:valT?):void>)
    __builtin_table_lock(Tab)
    var val = __builtin_table_find(Tab,at)
    invoke(blk,val)
    __builtin_table_unlock(Tab)

def find_if_exists(Tab:table<auto(keyT);auto(valT)>;at:keyT;blk:block<(p:valT?):void>)
    var val = __builtin_table_find(Tab,at)
    if val != null
        __builtin_table_lock(Tab)
        invoke(blk,val)
        __builtin_table_unlock(Tab)
        return true
    else
        return false

def find(Tab:table<auto(keyT);auto(valT)>;at:keyT):valT const?
    unsafe
        return reinterpret<valT const?>(__builtin_table_find(Tab,at))

def find(Tab:table<auto(keyT);auto(valT)>#;at:keyT):valT const?#
    unsafe
        return reinterpret<valT const?#>(__builtin_table_find(Tab,at))

def find_for_edit(var Tab:table<auto(keyT);auto(valT)>;at:keyT;blk:block<(var p:valT?):void>)
    __builtin_table_lock(Tab)
    var val = __builtin_table_find(Tab,at)
    invoke(blk,val)
    __builtin_table_unlock(Tab)

def find_for_edit_if_exists(var Tab:table<auto(keyT);auto(valT)>;at:keyT;blk:block<(var p:valT?):void>)
    var val = __builtin_table_find(Tab,at)
    if val != null
        __builtin_table_lock(Tab)
        invoke(blk,val)
        __builtin_table_unlock(Tab)

[unsafe_operation]
def find_for_edit(var Tab:table<auto(keyT);auto(valT)>;at:keyT):valT?
    return __builtin_table_find(Tab,at)

def erase(var Tab:table<auto(keyT);auto(valT)>;at:keyT):bool
    return __builtin_table_erase(Tab,at)

def key_exists(Tab:table<auto(keyT);auto(valT)>;at:keyT):bool
    return __builtin_table_key_exists(Tab,at)

def binary_save(obj; subexpr:block<(data:array<uint8>):void>)
    concept_assert(typeinfo(is_ref_type obj),"can only serialize ref types")
    _builtin_binary_save(obj,subexpr)

def binary_load(var obj; data:array<uint8>)
    concept_assert(typeinfo(is_ref_type obj),"can only serialize ref types")
    _builtin_binary_load(obj,data)

def clone_to_move(clone_src:auto(TT) implicit) : TT -const -#
    var clone_dest : TT - #
    clone_dest := clone_src
    return <- clone_dest

def clone_dim(var a;b:auto implicit)
    static_if typeinfo(is_dim a) && typeinfo(is_dim b) && typeinfo(dim a)==typeinfo(dim b)
        for aV,bV in a,b
            aV := bV
    else
        concept_assert(false,"can't clone this array")

def clone(var a:array<auto(TT)>;b:array<TT>)
    resize(a,length(b))
    for aV,bV in a,b
        aV := bV

def clone(var a:array<auto(TT)>;b:array<TT>#)
    resize(a,length(b))
    for aV,bV in a,b
        aV := bV

def clone(var a:table<auto(KT);auto(VT)>;b:table<KT;VT>)
    clear(a)
    for k,v in keys(b),values(b)
        a[k] := v

def clone(var a:table<auto(KT);auto(VT)>;b:table<KT;VT>#)
    clear(a)
    for k,v in keys(b),values(b)
        a[k] := v

def keys(a:table<auto(keyT);auto(valT)>) : iterator<keyT & const>
    var it : iterator<keyT & const>
    __builtin_table_keys(it,a,typeinfo(sizeof type<keyT>))
    return <- it

def values(a:table<auto(keyT);auto(valT)> =const) : iterator<valT & const>
    var it : iterator<valT & const>
    __builtin_table_values(it,a,typeinfo(sizeof type<valT>))
    return <- it

def values(var a:table<auto(keyT);auto(valT)> =const) : iterator<valT &>
    var it : iterator<valT &>
    __builtin_table_values(it,a,typeinfo(sizeof type<valT>))
    return <- it

def finalize_dim(var a : auto(TT)[])
    static_if typeinfo(can_delete type<TT>)
        for aV in a
            unsafe
                delete aV
    else
        concept_assert(false,"can't finalize this array")

def finalize(var a:array<auto(TT)>)
    static_if typeinfo(can_delete type<TT>)
        for aV in a
            unsafe
                delete aV
    __builtin_array_free(a,typeinfo(sizeof type<TT>))

def finalize(var a:table<auto(TK);auto(TV)>)
    static_if typeinfo(can_delete type<TV>)
        for aV in values(a)
            unsafe
                delete aV
    __builtin_table_free(a,typeinfo(sizeof type<TK>),typeinfo(sizeof type<TV>))

// temporal

def lock ( Tab : table<auto(keyT);auto(valT)>; blk : block<(t : table<keyT;valT>#):void >  )
    __builtin_table_lock(Tab)
    unsafe
        invoke(blk,reinterpret<table<auto(keyT);auto(valT)> const implicit>(Tab))
    __builtin_table_unlock(Tab)

def lock ( Tab : table<auto(keyT);auto(valT)>#; blk : block<(t : table<keyT;valT>#):void >  )
    invoke(blk,Tab)

def lock_forever ( var Tab : table<auto(keyT);auto(valT)> ) : table<keyT;valT> #
    __builtin_table_lock(Tab)
    unsafe
        return <- reinterpret<table<keyT;valT> #>(Tab)

// functional

def next ( it:iterator<auto(TT)>; var value : TT& ) : bool
    static_if !typeinfo(can_copy type<TT>)
        concept_assert(false, "requires type which can be copied")
    static_elif typeinfo(is_ref_value type<TT>)
        var pValue : TT - & ?
        unsafe
            if _builtin_iterator_iterate(it, addr(pValue))
                value = *pValue
                return true
            else
                return false
    else
        unsafe
            return _builtin_iterator_iterate(it, addr(value))

[generic]
def each ( rng : range ) : iterator<int>
    var it : iterator<int>
    _builtin_make_range_iterator(it,rng)
    return <- it

[generic,unsafe_operation]
def each ( str : string ) : iterator<int>
    var it : iterator<int>
    _builtin_make_string_iterator(it,str)
    return <- it

[unsafe_operation]
def each ( a : auto(TT)[] ) : iterator<TT&>
    unsafe
        var parr : void? = reinterpret<void?>(addr(a[0]))
        var it : iterator<TT&>
        _builtin_make_fixed_array_iterator(it,parr,typeinfo(dim a),typeinfo(sizeof type<TT>))
        return <- it

[unsafe_operation]
def each ( a : array<auto(TT)> ) : iterator<TT&>
    var it : iterator<TT&>
    _builtin_make_good_array_iterator(it, a, typeinfo(sizeof type<TT>))
    return <- it

def each ( lam : lambda<(var arg:auto(argT)):bool> ) : iterator<argT -&>
    concept_assert(typeinfo(is_ref type<argT>),"lamda-to-iterator argument has to be reference; expecting value& or reference type")
    var it : iterator<argT -&>
    _builtin_make_lambda_iterator(it,lam)
    return <- it

def each_ref ( lam : lambda<(var arg:auto(argT)?):bool> ) : iterator<argT &>
    var it : iterator<argT &>
    _builtin_make_lambda_iterator(it, lam)
    return <- it

def each_enum(tt:auto(TT)) : iterator<TT -const -&>
    concept_assert(typeinfo(is_enum tt),"expecting each_enum(any enum value)")
    var iter : iterator<TT -const -&>
    _builtin_make_enum_iterator(iter)
    return <- iter

def nothing( var it : iterator<auto(TT)> ) : iterator<TT>
    _builtin_make_nil_iterator(it)
    return <- it

def to_array ( it : iterator<auto(TT)> ) : array<TT -const -&>
    var arr : array<TT -const -&>
    for x in it
        push_clone(arr,x)
    return <- arr

def to_array(a:auto(TT)[]) : array<TT -const>
    var arr : array<TT -const>
    resize(arr,length(a))
    unsafe
        reinterpret<TT -const[typeinfo(dim a)]>(addr(arr[0])) := a
    return <- arr

def to_array_move(var a:auto(TT)[]) : array<TT -const>
    var arr : array<TT -const>
    static_if typeinfo(can_copy a)
        resize(arr,length(a))
        unsafe
            reinterpret<TT -const[typeinfo(dim a)]>(addr(arr[0])) = a
    static_elif typeinfo(can_move a)
        resize(arr,length(a))
        unsafe
            reinterpret<TT -const[typeinfo(dim a)]>(addr(arr[0])) <- a
    else
        concept_assert(false,"this array can't be copied or moved")
    return <- arr

def to_table(a:tuple<auto(keyT);auto(valT)>[]) : table<keyT -const;valT>
    var tab : table<keyT -const;valT>
    for x in a
        tab[x._0] := x._1
    return <- tab

def to_table_move(var a:tuple<auto(keyT);auto(valT)>[]) : table<keyT -const;valT>
    var tab : table<keyT -const;valT>
    static_if typeinfo(can_copy type<valT>)
        for x in a
            tab[x._0] = x._1
    static_elif typeinfo(can_move type<valT>)
        for x in a
            tab[x._0] <- x._1
    else
        concept_assert(false,"this array can't be copied or moved")
    return <- tab

def sort ( var a : auto(TT)[] )
    static_if typeinfo(is_numeric_comparable type<TT>)
        unsafe
            __builtin_sort ( addr(a[0]), length(a) )    // there is numeric specialization
    static_elif typeinfo(is_vector type<TT>)
        concept_assert(false,"there is no default compare function for vectors")
    static_elif typeinfo(is_string type<TT>)
        unsafe
            __builtin_sort_string ( addr(a[0]), length(a) )     // there is string specialization
    else
        unsafe
            __builtin_sort_any_cblock ( addr(a[0]), typeinfo(sizeof type<TT>), length(a) ) <| $ ( x, y  : TT ) : bool
                return x < y

def sort ( var a : array<auto(TT)> )
    __builtin_array_lock(a)
    static_if typeinfo(is_numeric_comparable type<TT>)
        unsafe
            __builtin_sort ( addr(a[0]), length(a) )    // there is numeric specialization
    static_elif typeinfo(is_vector type<TT>)
        concept_assert(false,"there is no default compare function for vectors")
    static_elif typeinfo(is_string type<TT>)
        unsafe
            __builtin_sort_string ( addr(a[0]), length(a) )     // there is string specialization
    else
        unsafe
            __builtin_sort_any_cblock ( addr(a[0]), typeinfo(sizeof type<TT>), length(a) ) <| $ ( x, y  : TT ) : bool
                return x < y
    __builtin_array_unlock(a)

def sort ( var a : auto(TT)[]; cmp : block<(x,y:TT):bool> )
    static_if typeinfo(is_numeric_comparable type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    static_elif typeinfo(is_vector type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    static_elif typeinfo(is_string type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    else
        unsafe
            __builtin_sort_any_cblock ( addr(a[0]), typeinfo(sizeof type<TT>), length(a), cmp )

def sort ( var a : array<auto(TT)>; cmp : block<(x,y:TT):bool> )
    __builtin_array_lock(a)
    static_if typeinfo(is_numeric_comparable type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    static_elif typeinfo(is_vector type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    static_elif typeinfo(is_string type<TT>)
        unsafe
            __builtin_sort_cblock ( addr(a[0]), length(a), cmp )
    else
        unsafe
            __builtin_sort_any_cblock ( addr(a[0]), typeinfo(sizeof type<TT>), length(a), cmp )
    __builtin_array_unlock(a)

def find_index ( arr : array<auto(TT)> implicit; key : TT )
    for i in range(0,length(arr))
        if arr[i]==key
            return i
    return -1

def find_index ( arr : auto(TT)[] implicit; key : TT )
    for i in range(0,length(arr))
        if arr[i]==key
            return i
    return -1

def find_index_if ( arr : array<auto(TT)> implicit; blk : block<(key:TT):bool> )
    for i in range(0,length(arr))
        if invoke(blk,arr[i])
            return i
    return -1

def find_index_if ( arr : auto(TT)[] implicit; blk : block<(key:TT):bool> )
    for i in range(0,length(arr))
        if invoke(blk,arr[i])
            return i
    return -1

def has_value ( a; key )
    static_if typeinfo(is_iterable a)
        for t in a
            if t == key
                return true
        return false
    else
        concept_assert(false,"can't iterate over source. has_value is meaningless")
        return false

def get_ptr ( src : smart_ptr<auto(TT)> ) : TT?
    unsafe
        return reinterpret<TT?> src

def get_command_line_arguments : array<string>
    var args : array<string>
    builtin_get_command_line_arguments(args)
    return <- args
