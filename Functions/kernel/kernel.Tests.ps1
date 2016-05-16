$here = Split-Path -Parent $MyInvocation.MyCommand.Path
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

        RPN 0 1       (q dup dup)  nip call | ShouldBeRPN 0 0 0
        RPN 0 1 2     (q dup dup) 2nip call | ShouldBeRPN 0 0 0
        RPN 0 1 2 3   (q dup dup) 3nip call | ShouldBeRPN 0 0 0
        RPN 0 1 2 3 4 (q dup dup) 4nip call | ShouldBeRPN 0 0 0
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

Describe Anaphoric {
    It if* {
        RPN $true  ::t ::f if* | ShouldBeRPN $true  dup ::t (q drop :f ) if
        RPN $false ::t ::f if* | ShouldBeRPN $false dup ::t (q drop :f ) if
        RPN $true  ::t ::f if* | ShouldBeRPN $true :t
        RPN $false ::t ::f if* | ShouldBeRPN :f
    }

    It when* {
        RPN $true  ::t when* | ShouldBeRPN $true  dup ::t :drop if
        RPN $false ::t when* | ShouldBeRPN $false dup ::t :drop if
        RPN $true  ::t when* | ShouldBeRPN $true  :t
        RPN $false ::t when* | ShouldBeRPN
    }

    It unless* {
        RPN $true  ::f unless* | ShouldBeRPN $true  dup (q ) (q drop :f ) if
        RPN $false ::f unless* | ShouldBeRPN $false dup (q ) (q drop :f ) if
        RPN $true  ::f unless* | ShouldBeRPN $true
        RPN $false ::f unless* | ShouldBeRPN :f
    }
}

Describe default {
    It '?if - if' {
        RPN $false $false :dup (q dup dup ) ?if | ShouldBeRPN $false $false dup (q nip dup ) (q drop dup dup ) if
        RPN $false $true  :dup (q dup dup ) ?if | ShouldBeRPN $false $true  dup (q nip dup ) (q drop dup dup ) if
    }

    It '?if - or' {
        # TODO: Implementation of `or`
        RPN $true  $false (q ) (q ) ?if | ShouldBeRPN $true  $false swap or
        RPN $false $false (q ) (q ) ?if | ShouldBeRPN $false $false swap or
    }
}

Describe Dippers {
    It dip {
        RPN 0 1 :dup dip | ShouldBeRPN 0 0 1
        RPN 0 (q drop drop) :dup dip call | ShouldBeRPN
        RPN 0 1 2 :dup :drop dip dip | ShouldBeRPN 0 0 1
        RPN | ShouldBeRPN 0 1 :drop (q drop ) dip call
    }

    It 2dip {
        RPN 0 1 2 :dup 2dip | ShouldBeRPN 0 0 1 2
        RPN 0 1 (q drop drop) :dup 2dip call | ShouldBeRPN 0
    }

    It _dip {
        RPN 0 1 2 3 :dup 3dip | ShouldBeRPN 0 0 1 2 3
        RPN 0 1 2 (q drop drop) :dup 3dip call | ShouldBeRPN 0 0

        RPN 0 1 2 3 4 :dup 4dip | ShouldBeRPN 0 0 1 2 3 4
        RPN 0 1 2 3 (q drop drop) :dup 4dip call | ShouldBeRPN 0 0 1
    }
}

Describe Keepers {
    It keep {
        RPN 0 1 :swap keep | ShouldBeRPN 0 1 swap 1
        RPN (q 0 dup ) :call keep call | ShouldBeRPN (q 0 dup ) call (q 0 dup ) call
    }

    It _keep {
        RPN 0 1 :swap 2keep | ShouldBeRPN 0 1 swap 0 1 
        RPN 0 (q 1 dup ) :call 2keep call | ShouldBeRPN 0 (q 1 dup ) call 0 (q 1 dup ) call
 
        RPN 0 1 2 :swap 3keep | ShouldBeRPN 0 1 2 swap 0 1 2
        RPN 0 1 (q 2 dup ) :call 3keep call | ShouldBeRPN 0 1 (q 2 dup ) call 0 1 (q 2 dup ) call

       RPN 0 1 2 3 :swap 4keep | ShouldBeRPN 0 1 2 3 swap 0 1 2 3
       RPN 0 1 2 (q 3 dup ) :call 4keep call | ShouldBeRPN 0 1 2 (q 3 dup ) call 0 1 2 (q 3 dup ) call
    }
}

Describe Cleavers {
    It bi {
        RPN 0 :drop :drop bi | ShouldBeRPN 0 dup drop drop
        RPN 0 :drop :drop bi | ShouldBeRPN 0 :drop keep drop
    }

    It tri {
        RPN 0 :drop :drop :drop tri | ShouldBeRPN 0 dup drop dup drop drop
        RPN 0 :drop :drop :drop tri | ShouldBeRPN 0 :drop keep :drop keep drop
    }
}

Describe DoubleCleavers {
    It 2bi {
        RPN 0 1 :2drop :2drop 2bi | ShouldBeRPN 0 1 2dup 2drop 2drop
        RPN 0 1 :2drop :2drop 2bi | ShouldBeRPN 0 1 :2drop 2keep 2drop
    }

    It 2tri {
        RPN 0 1 :2drop :2drop :2drop 2tri | ShouldBeRPN 0 1 2dup 2drop 2dup 2drop 2drop
        RPN 0 1 :2drop :2drop :2drop 2tri | ShouldBeRPN 0 1 :2drop 2keep :2drop 2keep 2drop
    }
}

Describe TripleCleavers {
    It 3bi {
        RPN 0 1 2 :3drop :3drop 3bi | ShouldBeRPN 0 1 2 3dup 3drop 3drop
        RPN 0 1 2 :3drop :3drop 3bi | ShouldBeRPN 0 1 2 :3drop 3keep 3drop
    }

    It 3tri {
        RPN 0 1 2 :3drop :3drop :3drop 3tri | ShouldBeRPN 0 1 2 3dup 3drop 3dup 3drop 3drop
        RPN 0 1 2 :3drop :3drop :3drop 3tri | ShouldBeRPN 0 1 2 :3drop 3keep :3drop 3keep 3drop
    }
}

Describe Spreaders {
    It bi* {
        RPN 0 1 :dup :drop bi* | ShouldBeRPN 0 0
    }

    It tri* {
        RPN 0 1 2 :dup :drop :dup tri* | ShouldBeRPN 0 0 2 2
    }
}

Describe DoubleSpreaders {
    It 2bi* {
        RPN 0 1 2 3 :2dup :2drop 2bi* | ShouldBeRPN 0 1 0 1
    }

    It 2tri* {
         RPN 0 1 2 3 4 5 :2dup :2drop :2dup 2tri* | ShouldBeRPN 0 1 0 1 4 5 4 5
    }
}

Describe Appliers {
    It bi@ {
        RPN 0 1 :dup bi@ | ShouldBeRPN 0 0 1 1
    }

    It tri@ {
        RPN 0 1 2 :dup tri@ | ShouldBeRPN 0 0 1 1 2 2
    }
}

Describe DoubleAppliers {
    It 2bi@ {
        RPN 0 1 2 3 :2dup 2bi@ | ShouldBeRPN 0 1 0 1 2 3 2 3
    }

    It 2tri@ {
        RPN 0 1 2 3 4 5 :2dup 2tri@ | ShouldBeRPN 0 1 0 1 2 3 2 3 4 5 4 5
    }
}

Describe QuotationBuilding {
    It curry {
        RPN 0 :dup curry call | ShouldBeRPN (q 0 dup) call
        RPN 0 (q 1 swap) curry call | ShouldBeRPN (q 0 1 swap) call
    }

    It 2curry {
        RPN 0 1 :swap 2curry call | ShouldBeRPN (q 0 1 swap) call
        RPN 0 1 (q 2 :swap dip) 2curry call | ShouldBeRPN (q 0 1 2 :swap dip) call
    }

    It 3curry {
        RPN 0 1 2 :3dup 3curry call | ShouldBeRPN (q 0 1 2 3dup) call
        RPN 0 1 2 (q 3 :swap 2dip) 2curry call | ShouldBeRPN (q 0 1 2 3 :swap 2dip) call
    }

    It with {
        $param, $obj, $A, $B = ':x', ':y', '2dup', 'call'
        RPN $param $obj (q $A ) with $B | ShouldBeRPN $obj (q $param swap $A ) $B
    }

    It 2with {
        $param1, $param2, $obj, $A, $B = ':x', ':y', ':z', '3dup', 'call'
        RPN $param1 $param2 $obj (q $A ) 2with $B | ShouldBeRPN $obj (q $param1 $param2 rot $A ) $B
    }

    It compose {
        $A, $B = 'dup', 'drop'

        RPN 0 (q $A ) (q $B ) compose call | ShouldBeRPN 0 (q $A $B ) call
        RPN 0 :$A :$B compose call | ShouldBeRPN 0 (q $A $B ) call
    }

    It prepose {
        $A, $B = 'drop', 'dup'

        RPN 0 (q $A ) (q $B ) prepose call | ShouldBeRPN 0 (q $B $A ) call
        RPN 0 :$A :$B prepose call | ShouldBeRPN 0 (q $B $A ) call
    }
}

Describe CurriedCleavers {
    It bi-curry {
        $x, $y, $z = 0, 1, 2
        $A1, $B1 =  'dup',  'drop'
        $A2, $B2 = '2dup', '2drop'
        $A3, $B3 = '3dup', '3drop'

        RPN $x (q $A1 ) (q $B1 ) bi-curry :call bi@ | ShouldBeRPN $x (q $A1 ) (q $B1 ) bi
        RPN $x $y    (q $A2 ) (q $B2 ) bi-curry bi | ShouldBeRPN $x $y    (q $A2 ) (q $B2 ) 2bi
        RPN $x $y $z (q $A3 ) (q $B3 ) bi-curry bi-curry bi | ShouldBeRPN $x $y $z (q $A3 ) (q $B3 ) 3bi
        RPN $x $y $z (q $A2 ) (q $B2 ) bi-curry bi* | ShouldBeRPN $x $z $y $z (q $A2 ) (q $B2 ) 2bi*

        RPN $x :$A1 :$B1 bi-curry :call bi@ | ShouldBeRPN $x :$A1 :$B1 bi
        RPN $x $y    :$A2 :$B2 bi-curry bi | ShouldBeRPN $x $y    :$A2 :$B2 2bi
        RPN $x $y $z :$A3 :$B3 bi-curry bi-curry bi | ShouldBeRPN $x $y $z :$A3 :$B3 3bi
        RPN $x $y $z :$A2 :$B2 bi-curry bi* | ShouldBeRPN $x $z $y $z :$A2 :$B2 2bi*
    }

    It tri-curry {
        $x, $y, $z = 0, 1, 2
        $A1, $B1, $C1 =  'dup',  'drop',  'dup'
        $A2, $B2, $C2 = '2dup', '2drop', '2dup'
        $A3, $B3, $C3 = '3dup', '3drop', '3dup'

        RPN $x (q $A1 ) (q $B1 ) (q $C1 ) tri-curry :call tri@ | ShouldBeRPN $x (q $A1 ) (q $B1 ) (q $C1 ) tri
        RPN $x $y (q $A2 ) (q $B2 ) (q $C2 ) tri-curry tri | ShouldBeRPN $x $y (q $A2 ) (q $B2 ) (q $C2 ) 2tri
        RPN $x $y $z (q $A3 ) (q $B3 ) (q $C3 ) tri-curry tri-curry tri | ShouldBeRPN $x $y $z (q $A3 ) (q $B3 ) (q $C3 ) 3tri

        RPN $x :$A1 :$B1 :$C1 tri-curry :call tri@ | ShouldBeRPN $x :$A1 :$B1 :$C1 tri
        RPN $x $y :$A2 :$B2 :$C2 tri-curry tri | ShouldBeRPN $x $y :$A2 :$B2 :$C2 2tri
        RPN $x $y $z :$A3 :$B3 :$C3 tri-curry tri-curry tri | ShouldBeRPN $x $y $z :$A3 :$B3 :$C3 3tri
    }

    It bi-curry* {
        $x, $y, $z = 0, 1, 2
        $A1, $B1, $C1 =  'dup',  'drop',  'dup'
        
        RPN $x $y (q $A1 ) (q $B1 ) bi-curry* :call bi@ | ShouldBeRPN $x $y (q $A1 ) (q $B1 ) bi*
        RPN $x $y $z (q $A1 ) (q $B1 ) bi-curry* bi | ShouldBeRPN $x $y $z :over dip (q $A1 ) (q $B1 ) 2bi*

        RPN $x $y :$A1 :$B1 bi-curry* :call bi@ | ShouldBeRPN $x $y :$A1 :$B1 bi*
        RPN $x $y $z :$A1 :$B1 bi-curry* bi | ShouldBeRPN $x $y $z :over dip :$A1 :$B1 2bi*
    }

    It tri-curry* {
        $x, $y, $z, $w = 0, 1, 2, 3
        $A1, $B1, $C1 =  'dup',  'drop',  'dup'
        $A2, $B2, $C2 = '2dup', '2drop', '2dup'

        RPN $x $y $z (q $A1 ) (q $B1 ) (q $C1 ) tri-curry* :call tri@ | ShouldBeRPN $x $y $z (q $A1 ) (q $B1 ) (q $C1 ) tri*
        RPN $x $y $z $w (q $A2 ) (q $B2 ) (q $C2 ) tri-curry* tri | ShouldBeRPN $x $y $z $w (q :over dip over ) dip (q $A2 ) (q $B2 ) (q $C2 ) 2tri*

        RPN $x $y $z $w :$A2 :$B2 :$C2 tri-curry* :call tri@ | ShouldBeRPN $x $y $z $w :$A2 :$B2 :$C2 tri*
        RPN $x $y $z $w :$A2 :$B2 :$C2 tri-curry* tri | ShouldBeRPN $x $y $z $w (q :over dip over ) dip :$A2 :$B2 :$C2 2tri*
    }

    It bi-curry@ {
        $x, $y = 0, 1
        $A = 'dup'

        RPN $x $y (q $A ) bi-curry@ :call bi@ | ShouldBeRPN $x $y (q $A ) (q $A ) bi-curry* :call bi@
        RPN $x $y :$A bi-curry@ :call bi@ | ShouldBeRPN $x $y :$A :$A bi-curry* :call bi@
    }

    It tri-curry@ {
        $x, $y, $z = 0, 1, 2
        $A = 'dup'

        RPN $x $y $z (q $A ) tri-curry@ :call tri@ | ShouldBeRPN $x $y $z (q $A ) (q $A ) (q $A ) tri-curry* :call tri@
    }
}
