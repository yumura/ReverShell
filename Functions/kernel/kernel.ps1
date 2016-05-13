# Stack stuff
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
    # TODO: implementation of `2dip`
