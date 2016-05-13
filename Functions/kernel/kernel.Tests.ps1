﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

$parent = Split-Path -Parent $here

. "$parent\Core.ps1"
. "$here\$sut"

filter ShouldBeRPN
{
    $stack1 = $_
    $stack2 = RPN @args

    while ($stack1.Count -gt 0)
        {$stack1.Pop() | Should Be $stack2.Pop()}
            
    $stack1.Count | Should Be $stack2.Count
}

Describe "Stack stuff" {
    It "dropers" {
        RPN 0 1        drop | ShouldBeRPN 0
        RPN 0 1 2     2drop | ShouldBeRPN 0
        RPN 0 1 2 3   3drop | ShouldBeRPN 0
        RPN 0 1 2 3 4 4drop | ShouldBeRPN 0
    }

    It "dupers" {
        RPN 0        dup | ShouldBeRPN 0 0
        RPN 0 1     2dup | ShouldBeRPN 0 1 0 1
        RPN 0 1 2   3dup | ShouldBeRPN 0 1 2 0 1 2
        RPN 0 1 2 3 4dup | ShouldBeRPN 0 1 2 3 0 1 2 3
    }

    It "nipers" {
        RPN 0 1        nip | ShouldBeRPN 1
        RPN 0 1 2     2nip | ShouldBeRPN 2
        RPN 0 1 2 3   3nip | ShouldBeRPN 3
        RPN 0 1 2 3 4 4nip | ShouldBeRPN 4
    }

    It "shuffle!" {
        RPN 0 1 2 rot-  | ShouldBeRPN 2 0 1
        RPN 0 1   dupd  | ShouldBeRPN 0 0 1
        RPN 0 1   over  | ShouldBeRPN 0 1 0
        RPN 0 1 2 pick  | ShouldBeRPN 0 1 2 0 
        RPN 0 1 2 rot   | ShouldBeRPN 1 2 0
        RPN 0 1   swap  | ShouldBeRPN 1 0
        RPN 0 1 2 swapd | ShouldBeRPN 1 0 2

        RPN 0 1 2 2over | ShouldBeRPN 0 1 2 0 1
        RPN 0 1 2 clear | ShouldBeRPN 
    }
}

Describe Combinators {
    It call {
        RPN 1 2 :swap call | ShouldBeRPN 2 1
        RPN 1 2 (q dup dup ) call | ShouldBeRPN 1 2 2 2
        RPN ::str call | ShouldBeRPN :str
        RPN 1 2 ::swap  call call | ShouldBeRPN 2 1
        RPN 1 2  :swap :call call | ShouldBeRPN 2 1
    }

    It ? {
        RPN $true  :t :f ? | ShouldBeRPN :t
        RPN $false :t :f ? | ShouldBeRPN :f

        RPN ::t ::f $true  (q drop call ) (q nip call ) ? call | ShouldBeRPN :t
        RPN ::t ::f $false (q drop call ) (q nip call ) ? call | ShouldBeRPN :f
    }

    It if {
        RPN 1 $true  :dup :drop if | ShouldBeRPN 1 1
        RPN 1 $false :dup :drop if | ShouldBeRPN
    }
}

Describe 'Single branch' {
    It when {
        RPN $true  ::t when | ShouldBeRPN :t
        RPN $false ::t when | ShouldBeRPN
    }

    It unless {
        RPN $true  ::f unless | ShouldBeRPN
        RPN $false ::f unless | ShouldBeRPN :f
    }
}
