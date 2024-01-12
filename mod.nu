use std *

export def assert-value-type [
  value: any,
  acceptedTypes: list<string>,
  --metadata(-m): any
] {
  let type = $value | describe
  if $type not-in $acceptedTypes {
    let acceptedTypes = $acceptedTypes | str join ", "
    let metadata = $metadata | default (metadata $value)
    error make {
      msg: "Invalid type",
      label: {
        text: $"expected: ($acceptedTypes) / actual: ($type)",
        span: $metadata.span
      }
    }
  }
}

def accumulate [
  accumulator: closure,
  --default: any
] : list<any> -> any {
  let records = $in
  let length = ($records | length)
  if $length == 0 {
    return $default
  }

  let first = ($records | get 0)
  if $length == 1 {
    return $first
  }

  let rest = $records | skip 1

  $rest
    | reduce --fold $first $accumulator
}


def max-impl [
  --comparer: closure,
  --selector: closure
] : list<any> -> any {
  let records = $in

  let values = if $selector != null {
    $records | each {|e| do $selector $e }
  } else {
    $records
  }

  let max = $values
    | enumerate
    | accumulate {|it, acc|
      let result = if $comparer != null {
        do $comparer $it.item $acc.item
      } else {
        $it.item - $acc.item
      }

      if (0 < ($result | into int)) {
        $it
      } else {
        $acc
      }
    } --default null

    if $max == null {
      null
    } else {
      $records | get $max.index
    }
}

export def max [
  comparer?: closure
] : list<any> -> any {
  let records = $in
  $records | max-impl --comparer $comparer
}

export def max-by [
  selector: any
] : list<any> -> any {
  let records = $in
  assert-value-type $selector ["closure", "string", "int"] -m (metadata $selector)
  let selector = match ($selector | describe) {
    "int" | "string" => ({|e| $e | get $selector}),
    "closure" => $selector
  }
  $records | max-impl --selector $selector
}

def min-impl [
  --comparer: closure,
  --selector: closure
] : list<any> -> any {
  let records = $in

  let values = if $selector != null {
    $records | each {|e| do $selector $e }
  } else {
    $records
  }

  let min = $values
    | enumerate
    | accumulate {|it, acc|
      let result = if $comparer != null {
        do $comparer $it.item $acc.item
      } else {
        $it.item - $acc.item
      }

      if (0 < ($result | into int)) {
        $acc
      } else {
        $it
      }
    } --default null

    if $min == null {
      null
    } else {
      $records | get $min.index
    }
}

export def min [
  comparer?: closure
] : list<any> -> any {
  let records = $in
  $records | min-impl --comparer $comparer
}

export def min-by [
  selector: any
] : list<any> -> any {
  let records = $in
  assert-value-type $selector ["closure", "string", "int"] -m (metadata $selector)
  let selector = match ($selector | describe) {
    "int" | "string" => ({|e| $e | get $selector}),
    "closure" => $selector
  }
  $records | min-impl --selector $selector
}

export def base-26 [
  --lower-case(-l)
] {
  let value = $in
  assert-value-type $value [int]

  assert greater or equal $value 0

  generate $value {|v|
    let d = $v mod 26
    let next = $v // 26
    if $next == 0 {
      {out: $d}
    } else {
      {out: $d, next: $next}
    }
  }
  | update 0 {|d| $d + 1}
  | reverse
  | each {|d|
    let code = if $lower_case {
      0x60 + $d
    } else {
      0x40 + $d
    }
    char --integer $code
  }
  | str join
}