﻿# Stack stuff
# ===========

fun drop ' x -- ' {} 1
foreach ($i in 2..10)
{
    $arr = 0..($i-1) | %{"`$_${_}"}
    $in  = $arr -join ' '

    $name = "${i}drop"
    $effect = " ${in} -- "
    fun $name $effect {} $i
}

fun dup ' x -- x x ' {$_0, $_0} 1
foreach ($i in 2..10)
{
    $arr = 0..($i-1) | %{"`$_${_}"}
    $in  = $arr -join ' '

    $name = "${i}dup"
    $effect = " ${in} -- ${in} ${in} "
    $sb = [ScriptBlock]::Create((($arr * 2) -join ', ')) 
  
    fun $name $effect $sb $i
}

fun nip ' $_0 $_1 -- $_1 ' {,$_1} 2
foreach ($i in 2..10)
{
    $arr = 0..$i | %{"`$_${_}"}
    $in  = $arr -join ' '
    $out = "`$_${i}"

    $name = "${i}nip"
    $effect = " ${in} -- ${out} "
    $sb = [ScriptBlock]::Create(",${out}")
  
    fun $name $effect $sb ($i + 1)
}

fun  rot-  ' x y z -- z x y '   {$_2, $_0, $_1}      3
fun  dupd  ' x y   -- x x y '   {$_0, $_0, $_1}      2
fun  over  ' x y   -- x y x '   {$_0, $_1, $_0}      2
fun  pick  ' x y z -- x y z x ' {$_0, $_1, $_2, $_0} 3
fun  rot   ' x y z -- y z x '   {$_1, $_2, $_0}      3
fun  swap  ' x y   -- y x '     {$_1, $_0}           2
fun  swapd ' x y z -- y x z '   {$_1, $_0, $_2}      3

word 2over ' x y z -- x y z x y ' pick pick
fun  clear ' -- ' {param($stack) New-Object System.Collections.Stack} -IsWord


# Combinators
# ===========
fun call ' callable -- ' `
{
    param($stack)

    if ($_0 -isnot [string]) {return ,$stack | RPN @_0}
    
    ,$stack | RPN $_0

} 1 -IsWord

fun ? '? true false -- true/false' {if ($_0) {,$_1} else {,$_2}} 3
word if ' ..a ? true: ( ..a -- ..b ) false: ( ..a -- ..b ) -- ..b ' ? call

# Single branch
word when ' ..a ? true: ( ..a -- ..a ) -- ..a '`
    swap :call :drop if

word unless ' ..a ? false: ( ..a -- ..a ) -- ..a '`
    swap :drop :call if

# Anaphoric
word if* ' ..a ? true: ( ..a ? -- ..b ) false: ( ..a -- ..b ) -- ..b '`
    pick (q drop call ) (q 2nip call ) if

word when* ' ..a ? true: ( ..a ? -- ..a ) -- ..a '`
    over :call :2drop if

word unless* ' ..a ? false: ( ..a -- ..a x ) -- ..a x '`
    over :drop (q nip call ) if

# Default
word ?if ' ..a default cond true: ( ..a cond -- ..b ) false: ( ..a default -- ..b ) -- ..b '`
    pick (q drop :drop 2dip call ) (q 2nip call ) if

# Dippers
fun dip ' x quot -- x ' {
    param($stack)

    if ($_0 -is [string]) {$_0 = ":${_0}"}

    if ($_1 -isnot [string]) {return ,$stack | RPN @_1 $_0}
    
    ,$stack | RPN $_1 $_0

} 2 -IsWord

word 2dip ' x y quot -- x y ' swap :dip dip

foreach ($i in 3..10)
{
    $arr = 0..($i - 1) | %{"`$_${_}"}
    $out = $arr -join ' '

    $name = "${i}dip"
    $effect = " ${out} quot -- ${out} "
    $j = $i - 1

    word $name $effect swap ":${j}dip" dip
}

# Keepers
word keep ' ..a x quot: ( ..a x -- ..b ) -- ..b x '`
    over :call dip

foreach ($i in 2..10)
{
    $arr = 0..($i - 1) | %{"x${_}"}
    $k = $arr -join ' '
    $effect = " ..a ${k} quot: ( ..a ${k} -- ..b ) -- ..b ${k} "

    word "${i}keep" $effect ":${i}dup" dip "${i}dip"
}

# Cleavers
word bi ' x p q -- '`
    :keep dip call

word tri ' x p q r -- '`
    (q :keep dip keep ) dip call

# Double cleavers
word 2bi ' x y p q -- '`
    :2keep dip call

word 2tri ' x y p q r -- '`
    (q :2keep dip 2keep) dip call

# Triple cleavers
word 3bi 'x y z p q -- '`
    :3keep dip call

word 3tri ' x y z p q r -- '`
    (q :3keep dip 3keep ) dip call

# Spreaders
word bi* ' x y p q -- '`
    :dip dip call

word tri* ' x y z p q r -- '`
    (q :2dip dip dip ) dip call

# Double spreaders
word 2bi* ' w x y z p q -- '`
    :2dip dip call

word 2tri* ' u v w x y z p q r -- '`
    :4dip 2dip 2bi*

# Appliers
word bi@ ' x y quot -- '`
    dup bi*

word tri@ ' x y z quot -- '`
    dup dup tri*

# Double appliers
word 2bi@ ' w x y z quot -- '`
    dup 2bi*

word 2tri@ ' u v w x y z quot -- '`
    dup dup 2tri*

# Quotation building
fun curry ' obj quot -- curry '`
    {(q $_0 $_1 call )} 2

foreach ($i in 2..10)
{
    $arr = 0..$i | %{"`$_${_}"}
    $in = $arr -join ' '
    $effect = " ${in} -- curry "
    $sb = [ScriptBlock]::Create("(q ${in} call )")

    fun "${i}curry" $effect $sb ($i + 1)
}

word with ' param obj quot -- obj curry '`
    swapd (q swapd call ) 2curry

word 2with ' param1 param2 obj quot -- obj curry '`
    with with

fun compose ' quot1 quot2 -- compose ' {
    if ($_0 -is [string]) {$_0 = (q $_0 call)}
    if ($_1 -is [string]) {$_1 = (q $_1 call)}
    ,(q @_0 @_1)
} 2

word prepose ' quot1 quot2 -- compose '`
    swap compose

# Curried cleavers
fun bi-curry " x p q -- p' q' "`
    {(q $_0 $_1 call), (q $_0 $_2 call)} 3

fun tri-curry " x p q r -- p' q' r' "`
    {(q $_0 $_1 call), (q $_0 $_2 call), (q $_0 $_3 call)} 4

fun bi-curry* " x y p q -- p' q' "`
    {(q $_0 $_2 call), (q $_1 $_3 call)} 4

fun tri-curry* " x y z p q r -- p' q' r' "`
    {(q $_0 $_3 call), (q $_1 $_4 call), (q $_2 $_5 call)} 6

fun bi-curry@ " x y q -- p' q' "`
    {(q $_0 $_2 call), (q $_1 $_2 call)} 3

fun tri-curry@ " x y z q -- p' q' r' "`
    {(q $_0 $_3 call), (q $_1 $_3 call), (q $_2 $_3 call)} 4
