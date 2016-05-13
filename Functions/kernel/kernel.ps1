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

fun nip ' $_0 $_1 -- $_1 ' {$_1} 2
foreach ($i in 2..10)
{
    $arr = 0..$i | %{"`$_${_}"}
    $in  = $arr -join ' '
    $out = "`$_${i}"

    $name = "${i}nip"
    $effect = " ${in} -- ${out} "
    $sb = [ScriptBlock]::Create($out)
  
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
