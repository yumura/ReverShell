$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Core" {
    It "四則演算が定義できる" {
        fun + "x y -- z" {$_0 + $_1} 2
        fun - "x y -- z" {$_0 - $_1} 2
        fun * "x y -- z" {$_0 * $_1} 2
        fun / "x y -- z" {$_0 / $_1} 2

        RPN 3 4 2 * 1 5 - / + | Pop-RPN | Should Be 1
    }

    It "単項演算子が定義できる" {
        fun negate 'x -- y' {- $_0} 1
        RPN   3  negate | Pop-RPN | Should Be (-3)
        RPN (-3) negate | Pop-RPN | Should Be   3
        RPN   3  negate negate | Pop-RPN | Should Be 3
    }

    It "n項演算子が定義できる" {
        $sum = {$args | %{$w=0}{$w+=$_}{$w}}

        foreach ($i in 1..4)
        {
            $name   = "sum${i}"
            $xs     = (1..$i | %{"x${_}"}) -join ' ' 
            $effect = "${xs} -- y"

            fun $name $effect $sum $i
        }

        RPN 1       sum1 | Pop-RPN | Should Be  1
        RPN 1 2     sum2 | Pop-RPN | Should Be  3
        RPN 1 2 3   sum3 | Pop-RPN | Should Be  6
        RPN 1 2 3 4 sum4 | Pop-RPN | Should Be 10    
    }

    It "先頭がコロンであれば文字列として扱われる" {
        fun + "x y -- z" {$_0 + $_1} 2

        RPN :Hello :_  :World + + | Pop-RPN | Should Be 'Hello_World'
    }

    It "逆ポーランド記法で関数を定義できる" {
        fun dup  'x -- x x'   {$_0, $_0} 1
        fun swap 'x y -- y x' {$_1, $_0} 2

        word sq  'x -- y' dup *
        word neg 'x -- y' 0 swap -

        RPN 5 sq  | Pop-RPN | Should Be  25
        RPN 3 neg | Pop-RPN | Should Be (-3)
    }

    It "クォートを作成できる (q ...)" {
        fun if '? true false -- node' {
            param($stack)

            if ($_0) {,$stack | RPN @_1}
            else     {,$stack | RPN @_2}

        } 3 -IsWord

        fun drop 'x -- ' {} 1
        fun eq 'x y -- ?' {$_0 -eq $_1} 2
        fun lt 'x y -- ?' {$_0 -lt $_1} 2
        fun gt 'x y -- ?' {$_0 -gt $_1} 2

        word zero? 'x -- ?' 0 eq
        word sign-test 'x -- str' dup 0 lt (q drop :negative) (q zero? (q :zero) (q :positive) if) if

        RPN   1  sign-test | Pop-RPN | Should Be 'positive'
        RPN   0  sign-test | Pop-RPN | Should Be 'zero'
        RPN (-1) sign-test | Pop-RPN | Should Be 'negative'
    }
}
