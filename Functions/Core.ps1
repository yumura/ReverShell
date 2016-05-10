# Variable
# ========
$Script:RPNDictionary = @{}
$Script:StringHead = ':'


# Function
# ========
filter Global:Invoke-ReversePolishNotation
{
    $stack = if ($MyInvocation.ExpectingInput) {,$_}
             else {New-Object System.Collections.Stack}

    $args | %{
        if (Test-RPNValue $_) {Push-RPN $_ $stack}
        else {$stack = RPNEval $_ $stack}
    }

    ,$stack
}

filter Test-RPNValue ($Token)
    {$Token -isnot [string] -or $Token.StartsWith($Script:StringHead)}

filter Push-RPN ($Token, $Stack)
{
    if ($Token -isnot [string]) {return $stack.Push($Token)}

    $tail = $Token -replace "^${Script:StringHead}", ''
    $stack.Push($tail)
}

filter RPNEval ($name, $stack)
{
    $dict = $Script:RPNDictionary
    if (-not $dict.ContainsKey($name))
        {throw "関数 ${name} が定義されていません"}

    $fun = $dict[$name]
    if ($stack.Count -lt $fun.ArgsLength)
        {throw "関数 ${name} に対する被演算子が足りません"}

    if ($fun.IsWord) {return RPNEvalWord $fun $stack}
    RPNEvalFunction $fun $stack
}

filter RPNEvalWord ($fun, $stack)
{
    if ($fun.ArgsLength -le 0)
        {return ,(& $fun.ScriptBlock -stack $stack)}
        
    $argstack = New-Object System.Collections.Stack
    foreach ($i in ($fun.ArgsLength - 1)..0)
    {
        $value = $stack.Pop()
        Set-Variable "_${i}" $value
        $argstack.Push($value)
    }
    ,(& $fun.ScriptBlock -stack $stack)
}

filter RPNEvalFunction ($fun, $stack)
{
    if ($fun.ArgsLength -le 0)
    {
        & $fun.ScriptBlock | %{$stack.Push($_)}
        return ,$stack
    }    
    
    $argstack = New-Object System.Collections.Stack
    foreach ($i in ($fun.ArgsLength - 1)..0)
    {
        $value = $stack.Pop()
        Set-Variable "_${i}" $value
        $argstack.Push($value)
    }
    & $fun.ScriptBlock @argstack | %{$stack.Push($_)}
    return ,$stack
}

filter New-RPNFunction
{
    Param
    (
        [string]      $Name,
        [string]      $Effect,
        [ScriptBlock] $ScriptBlock,
        [int]         $ArgsLength,
        [switch]      $IsWord
    )
    
    if (-not $IsWord) {$PSBoundParameters['IsWord'] = $false}
    $Script:RPNDictionary[$Name] = New-Object PSCustomObject -Property $PSBoundParameters
}

filter New-RPNWord
{
    $name, $effect, $tail = $args
    $word = {
        param($stack)
        ,$stack | Global:Invoke-ReversePolishNotation @tail
    }.GetNewClosure()

    New-RPNFunction $name $effect $word 0 -IsWord
}

filter Get-RPNFunction ([string] $Name) {$Script:RPNDictionary[$Name]}

filter New-RPNQuote {,$args}

filter Pop-RPN {$_.Pop()}


# Alias
# =====
Set-Alias RPN  Invoke-ReversePolishNotation
Set-Alias fun  New-RPNFunction
Set-Alias word New-RPNWord
Set-Alias q    New-RPNQuote

