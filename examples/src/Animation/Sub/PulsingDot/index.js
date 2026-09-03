(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.bw.bo === region.m.bo)
	{
		return 'on line ' + region.bw.bo;
	}
	return 'on lines ' + region.bw.bo + ' through ' + region.m.bo;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.eM,
		impl.f$,
		impl.fB,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		aG: func(record.aG),
		cz: record.cz,
		cv: record.cv
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.aG;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.cz;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.cv) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.eM,
		impl.f$,
		impl.fB,
		function(sendToApp, initialModel) {
			var view = impl.f0;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.eM,
		impl.f$,
		impl.fB,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.cy && impl.cy(sendToApp)
			var view = impl.f0;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.dY);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.fU) && (_VirtualDom_doc.title = title = doc.fU);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.e4;
	var onUrlRequest = impl.e5;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		cy: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.dl === next.dl
							&& curr.cZ === next.cZ
							&& curr.di.a === next.di.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		eM: function(flags)
		{
			return A3(impl.eM, flags, _Browser_getUrl(), key);
		},
		f0: impl.f0,
		f$: impl.f$,
		fB: impl.fB
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { eF: 'hidden', d7: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { eF: 'mozHidden', d7: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { eF: 'msHidden', d7: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { eF: 'webkitHidden', d7: 'webkitvisibilitychange' }
		: { eF: 'hidden', d7: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		ds: _Browser_getScene(),
		dA: {
			ao: _Browser_window.pageXOffset,
			ap: _Browser_window.pageYOffset,
			cb: _Browser_doc.documentElement.clientWidth,
			bT: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		cb: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		bT: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			ds: {
				cb: node.scrollWidth,
				bT: node.scrollHeight
			},
			dA: {
				ao: node.scrollLeft,
				ap: node.scrollTop,
				cb: node.clientWidth,
				bT: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			ds: _Browser_getScene(),
			dA: {
				ao: x,
				ap: y,
				cb: _Browser_doc.documentElement.clientWidth,
				bT: _Browser_doc.documentElement.clientHeight
			},
			es: {
				ao: x + rect.left,
				ap: y + rect.top,
				cb: rect.width,
				bT: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\u000A    ',
		A2($elm$core$String$split, '\u000A', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\u000A\u000A(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\u0027' + (f + '\u0027]'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\u000A\u000A',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\u000A\u000A';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\u000A\u000A    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\u000A\u000A' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.x) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.C),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.C);
		} else {
			var treeLen = builder.x * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.D) : builder.D;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.x);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.C) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.C);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{D: nodeList, x: (len / $elm$core$Array$branchFactor) | 0, C: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {cT: fragment, cZ: host, dg: path, di: port_, dl: protocol, dm: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$Anim$Internal$Engine$Sub$AnimState = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$Run = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Started = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$AnimGroup = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Sub$Animations$Animations = $elm$core$Basics$identity;
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === -2) {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$add = F2(
	function (_v0, _v1) {
		var additional = _v0;
		var existing = _v1;
		return A2($elm$core$Dict$union, existing, additional);
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$addAnimation = F2(
	function (additional, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{
				bk: A2($author$project$Anim$Internal$Engine$Sub$Animations$add, additional, group.bk)
			});
	});
var $author$project$Anim$Internal$Builder$AnimateKind = 0;
var $author$project$Anim$Internal$Builder$AnimBuilder = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl = F3(
	function (f, acc, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$foldl, f, acc, dict);
	});
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$get = F2(
	function (name, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$get, name, dict);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$AnimGroups = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$insert = F3(
	function (name, value, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, name, value, dict);
	});
var $author$project$Anim$Internal$Builder$addToHistoryWithKind = F3(
	function (kind, processedData, _v0) {
		var data = _v0;
		return A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
			F3(
				function (animGroupName, groupConfig, _v1) {
					var accData = _v1;
					var state = accData.u;
					var newEntry = {E: groupConfig, cs: kind};
					var existingHistory = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, state.ay);
					var updatedHistory = function () {
						if (existingHistory.$ === 1) {
							return {aC: newEntry, a9: _List_Nil};
						} else {
							var existing = existingHistory.a;
							return {
								aC: newEntry,
								a9: A2($elm$core$List$cons, existing.aC, existing.a9)
							};
						}
					}();
					return _Utils_update(
						accData,
						{
							u: _Utils_update(
								state,
								{
									ay: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, updatedHistory, state.ay)
								})
						});
				}),
			data,
			processedData.co);
	});
var $author$project$Anim$Internal$Builder$addAnimationToHistory = $author$project$Anim$Internal$Builder$addToHistoryWithKind(0);
var $author$project$Anim$Internal$Builder$Normal = 0;
var $author$project$Anim$Internal$Builder$Once = {$: 0};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $author$project$Anim$Internal$Builder$CssUnitStore$empty = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$init = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Builder$initAnimation = {y: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, aO: $author$project$Anim$Internal$Builder$CssUnitStore$empty, p: $elm$core$Maybe$Nothing, d: $elm$core$Dict$empty, U: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, bB: $elm$core$Dict$empty};
var $author$project$Anim$Internal$Builder$clearAnimData = function (_v0) {
	var data = _v0;
	var pb = data.b;
	return _Utils_update(
		data,
		{
			a: $author$project$Anim$Internal$Builder$initAnimation,
			b: _Utils_update(
				pb,
				{w: 0, e: $elm$core$Dict$empty, f: $elm$core$Dict$empty, r: $author$project$Anim$Internal$Builder$Once})
		});
};
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Anim$Internal$Engine$Shared$PlayState$Running = 1;
var $author$project$Anim$Extra$TransformOrder$Rotate = 1;
var $author$project$Anim$Extra$TransformOrder$Scale = 3;
var $author$project$Anim$Extra$TransformOrder$Skew = 2;
var $author$project$Anim$Extra$TransformOrder$Translate = 0;
var $author$project$Anim$Extra$TransformOrder$default = _List_fromArray(
	[0, 1, 2, 3]);
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $author$project$Anim$Internal$Engine$Sub$Animations$fromList = A2($elm$core$Basics$composeR, $elm$core$Dict$fromList, $elm$core$Basics$identity);
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder = function (_v0) {
	var group = _v0;
	return group.o;
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$NotStarted = 0;
var $author$project$Anim$Internal$Engine$Sub$Animations$init = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$init = {w: 0, bk: $author$project$Anim$Internal$Engine$Sub$Animations$init, ci: 0, cj: $elm$core$Dict$empty, ck: $elm$core$Dict$empty, r: $author$project$Anim$Internal$Builder$Once, bc: 0, o: $author$project$Anim$Extra$TransformOrder$default, cC: ''};
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Anim$Internal$Builder$ProcessedOpacityConfig = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Property$Opacity$Opacity = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Opacity$default = 1;
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $author$project$Anim$Internal$Property$Opacity$distance = F2(
	function (_v0, _v1) {
		var o1 = _v0;
		var o2 = _v1;
		return $elm$core$Basics$abs(o2 - o1);
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$get = F2(
	function (key, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$get, key, dict);
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations = function (_v0) {
	var group = _v0;
	return group.bk;
};
var $elm$core$Basics$round = _Basics_round;
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Generator$scaleInterruptDuration = F2(
	function (maybeExisting, propertyConfig) {
		var _v0 = _Utils_Tuple2(maybeExisting, propertyConfig);
		if ((!_v0.a.$) && (_v0.b.$ === 2)) {
			var existing = _v0.a.a;
			var cfg = _v0.b.a;
			var _v1 = A2(
				$author$project$Anim$Internal$Engine$Sub$Animations$get,
				'opacity',
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(existing));
			if ((!_v1.$) && (_v1.a.$ === 2)) {
				var prev = _v1.a.a;
				if (prev.A) {
					return propertyConfig;
				} else {
					var prevDurationMs = prev.K;
					var prevDistance = A2($author$project$Anim$Internal$Property$Opacity$distance, prev.bw, prev.m);
					var nextStart = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Opacity$default, cfg.bw);
					var nextDistance = A2($author$project$Anim$Internal$Property$Opacity$distance, nextStart, cfg.m);
					var scaledDurationMs = ((prevDistance <= 0) || (prevDurationMs <= 0)) ? cfg.v : (nextDistance * (prevDurationMs / prevDistance));
					var scaledDurationInt = A2(
						$elm$core$Basics$max,
						0,
						$elm$core$Basics$round(scaledDurationMs));
					return $author$project$Anim$Internal$Builder$ProcessedOpacityConfig(
						_Utils_update(
							cfg,
							{v: scaledDurationInt}));
				}
			} else {
				return propertyConfig;
			}
		} else {
			return propertyConfig;
		}
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimationDirection = F2(
	function (direction, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{w: direction});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations = F2(
	function (animations, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{bk: animations});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration = F2(
	function (currentIteration, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{ci: currentIteration});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry = F2(
	function (entry, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{cj: entry});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit = F2(
	function (exit, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{ck: exit});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setIterationCount = F2(
	function (iterationCount, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{r: iterationCount});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState = F2(
	function (state, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{bc: state});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setTransformOrder = F2(
	function (transformOrder, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{o: transformOrder});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setWillChange = F2(
	function (value, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{cC: value});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$Opacity = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$Rotate = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Scale = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Size = F2(
	function (a, b) {
		return {$: 6, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$Skew = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Builder$Snap = {$: 1};
var $author$project$Anim$Internal$Engine$Sub$Animation$Translate = F2(
	function (a, b) {
		return {$: 8, a: a, b: b};
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$PerspectiveOrigin = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$default = {ao: 50, ap: 50};
var $author$project$Anim$Internal$Property$Rotate$Rotate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Rotate$default = {ao: 0, ap: 0, aq: 0};
var $author$project$Anim$Internal$Property$Scale$Scale = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Scale$default = {ao: 1.0, ap: 1.0, aq: 1.0};
var $author$project$Anim$Internal$Property$Size$Size = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Size$default = {cW: 0, P: 0};
var $author$project$Anim$Internal$Property$Skew$Skew = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Skew$default = {ao: 0, ap: 0};
var $author$project$Anim$Internal$Property$Translate$Translate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Translate$default = {ao: 0, ap: 0, aq: 0};
var $author$project$Anim$Internal$Extra$Color$Rgb = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Extra$Color$fromRGB = function (_v0) {
	var b = _v0.cI;
	var g = _v0.cV;
	var r = _v0.dn;
	return $author$project$Anim$Internal$Extra$Color$Rgb(
		{cI: b, cV: g, dn: r});
};
var $author$project$Anim$Internal$Builder$processedPropertyMode = function (prop) {
	switch (prop.$) {
		case 0:
			var cfg = prop.c;
			return cfg.O;
		case 1:
			var cfg = prop.b;
			return cfg.O;
		case 2:
			var cfg = prop.a;
			return cfg.O;
		case 3:
			var cfg = prop.a;
			return cfg.O;
		case 4:
			var cfg = prop.a;
			return cfg.O;
		case 5:
			var cfg = prop.a;
			return cfg.O;
		case 6:
			var cfg = prop.a;
			return cfg.O;
		case 7:
			var cfg = prop.a;
			return cfg.O;
		default:
			var cfg = prop.a;
			return cfg.O;
	}
};
var $author$project$Motion$Internal$Spring$unwrap = function (_v0) {
	var config = _v0;
	return config;
};
var $elm$core$Basics$cos = _Basics_cos;
var $elm$core$Basics$e = _Basics_e;
var $elm$core$Basics$pow = _Basics_pow;
var $elm$core$Basics$sin = _Basics_sin;
var $author$project$Shared$Spring$displacement = F2(
	function (sol, t) {
		switch (sol.$) {
			case 0:
				var b = sol.a.cI;
				var a = sol.a.cE;
				var zeta = sol.a.bF;
				var omegaD = sol.a.bW;
				var omega0 = sol.a.ah;
				return A2($elm$core$Basics$pow, $elm$core$Basics$e, ((-zeta) * omega0) * t) * ((a * $elm$core$Basics$cos(omegaD * t)) + (b * $elm$core$Basics$sin(omegaD * t)));
			case 1:
				var b = sol.a.cI;
				var a = sol.a.cE;
				var omega0 = sol.a.ah;
				return (a + (b * t)) * A2($elm$core$Basics$pow, $elm$core$Basics$e, (-omega0) * t);
			default:
				var b = sol.a.cI;
				var a = sol.a.cE;
				var r2 = sol.a.bu;
				var r1 = sol.a.bt;
				return (a * A2($elm$core$Basics$pow, $elm$core$Basics$e, r1 * t)) + (b * A2($elm$core$Basics$pow, $elm$core$Basics$e, r2 * t));
		}
	});
var $author$project$Shared$Spring$Critically = function (a) {
	return {$: 1, a: a};
};
var $author$project$Shared$Spring$Overdamped = function (a) {
	return {$: 2, a: a};
};
var $author$project$Shared$Spring$Underdamped = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $author$project$Shared$Spring$precompute = function (_v0) {
	var to = _v0.b7;
	var from = _v0.bR;
	var spring = _v0.bv;
	var x0 = from - to;
	var v0 = spring.ba;
	var m = A2($elm$core$Basics$max, 1.0e-6, spring.aT);
	var k = A2($elm$core$Basics$max, 0, spring.aZ);
	var omega0 = $elm$core$Basics$sqrt(k / m);
	var c = A2($elm$core$Basics$max, 0, spring.aP);
	var zeta = (k <= 0) ? 1.0 : (c / (2.0 * $elm$core$Basics$sqrt(k * m)));
	if ($elm$core$Basics$abs(zeta - 1.0) < 1.0e-4) {
		return $author$project$Shared$Spring$Critically(
			{cE: x0, cI: v0 + (omega0 * x0), ah: omega0});
	} else {
		if (zeta < 1.0) {
			var omegaD = omega0 * $elm$core$Basics$sqrt(1.0 - (zeta * zeta));
			return $author$project$Shared$Spring$Underdamped(
				{cE: x0, cI: (v0 + ((zeta * omega0) * x0)) / omegaD, ah: omega0, bW: omegaD, bF: zeta});
		} else {
			var disc = $elm$core$Basics$sqrt((zeta * zeta) - 1.0);
			var r1 = (-omega0) * (zeta - disc);
			var r2 = (-omega0) * (zeta + disc);
			var a = (v0 - (r2 * x0)) / (r1 - r2);
			return $author$project$Shared$Spring$Overdamped(
				{cE: a, cI: x0 - a, bt: r1, bu: r2});
		}
	}
};
var $author$project$Shared$Spring$valueAt = F2(
	function (params, timeMs) {
		return params.b7 + A2(
			$author$project$Shared$Spring$displacement,
			$author$project$Shared$Spring$precompute(params),
			timeMs / 1000.0);
	});
var $author$project$Anim$Internal$Engine$Sub$Generator$springEasingFunction = F2(
	function (s, durationMs) {
		var safeDuration = (durationMs <= 0) ? 1 : durationMs;
		var motion = {
			bR: 0,
			bv: $author$project$Motion$Internal$Spring$unwrap(s),
			b7: 1
		};
		return function (t) {
			return A2($author$project$Shared$Spring$valueAt, motion, t * safeDuration);
		};
	});
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm_community$easing_functions$Ease$bezier = F5(
	function (x1, y1, x2, y2, time) {
		var pair = F4(
			function (interpolate, _v2, _v3, v) {
				var a0 = _v2.a;
				var b0 = _v2.b;
				var a1 = _v3.a;
				var b1 = _v3.b;
				return _Utils_Tuple2(
					A3(interpolate, a0, a1, v),
					A3(interpolate, b0, b1, v));
			});
		var lerp = F3(
			function (from, to, v) {
				return from + ((to - from) * v);
			});
		var casteljau = function (ps) {
			if (ps.b && (!ps.b.b)) {
				var _v1 = ps.a;
				var x = _v1.a;
				var y = _v1.b;
				return y;
			} else {
				var xs = ps;
				return casteljau(
					A3(
						$elm$core$List$map2,
						F2(
							function (x, y) {
								return A4(pair, lerp, x, y, time);
							}),
						xs,
						A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							$elm$core$List$tail(xs))));
			}
		};
		return casteljau(
			_List_fromArray(
				[
					_Utils_Tuple2(0, 0),
					_Utils_Tuple2(x1, y1),
					_Utils_Tuple2(x2, y2),
					_Utils_Tuple2(1, 1)
				]));
	});
var $elm_community$easing_functions$Ease$inBack = function (time) {
	return (time * time) * ((2.70158 * time) - 1.70158);
};
var $elm_community$easing_functions$Ease$flip = F2(
	function (easing, time) {
		return 1 - easing(1 - time);
	});
var $elm_community$easing_functions$Ease$outBounce = function (time) {
	var t4 = time - (2.625 / 2.75);
	var t3 = time - (2.25 / 2.75);
	var t2 = time - (1.5 / 2.75);
	var a = 7.5625;
	return (_Utils_cmp(time, 1 / 2.75) < 0) ? ((a * time) * time) : ((_Utils_cmp(time, 2 / 2.75) < 0) ? (((a * t2) * t2) + 0.75) : ((_Utils_cmp(time, 2.5 / 2.75) < 0) ? (((a * t3) * t3) + 0.9375) : (((a * t4) * t4) + 0.984375)));
};
var $elm_community$easing_functions$Ease$inBounce = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outBounce);
var $elm_community$easing_functions$Ease$outCirc = function (time) {
	return $elm$core$Basics$sqrt(
		1 - A2($elm$core$Basics$pow, time - 1, 2));
};
var $elm_community$easing_functions$Ease$inCirc = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$inCubic = function (time) {
	return A2($elm$core$Basics$pow, time, 3);
};
var $elm$core$Basics$pi = _Basics_pi;
var $elm_community$easing_functions$Ease$inElastic = function (time) {
	if (time === 0.0) {
		return 0.0;
	} else {
		var t = time - 1;
		var s = 0.075;
		var p = 0.3;
		return -(A2($elm$core$Basics$pow, 2, 10 * t) * $elm$core$Basics$sin(((t - s) * (2 * $elm$core$Basics$pi)) / p));
	}
};
var $elm_community$easing_functions$Ease$inExpo = function (time) {
	return (time === 0.0) ? 0.0 : A2($elm$core$Basics$pow, 2, 10 * (time - 1));
};
var $elm_community$easing_functions$Ease$inOut = F3(
	function (e1, e2, time) {
		return (time < 0.5) ? (e1(time * 2) / 2) : (0.5 + (e2((time - 0.5) * 2) / 2));
	});
var $elm_community$easing_functions$Ease$outBack = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inBack);
var $elm_community$easing_functions$Ease$inOutBack = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBack, $elm_community$easing_functions$Ease$outBack);
var $elm_community$easing_functions$Ease$inOutBounce = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBounce, $elm_community$easing_functions$Ease$outBounce);
var $elm_community$easing_functions$Ease$inOutCirc = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCirc, $elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$outCubic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inCubic);
var $elm_community$easing_functions$Ease$inOutCubic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCubic, $elm_community$easing_functions$Ease$outCubic);
var $elm_community$easing_functions$Ease$outElastic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inElastic);
var $elm_community$easing_functions$Ease$inOutElastic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inElastic, $elm_community$easing_functions$Ease$outElastic);
var $elm_community$easing_functions$Ease$outExpo = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inExpo);
var $elm_community$easing_functions$Ease$inOutExpo = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inExpo, $elm_community$easing_functions$Ease$outExpo);
var $elm_community$easing_functions$Ease$inQuad = function (time) {
	return A2($elm$core$Basics$pow, time, 2);
};
var $elm_community$easing_functions$Ease$outQuad = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuad);
var $elm_community$easing_functions$Ease$inOutQuad = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuad, $elm_community$easing_functions$Ease$outQuad);
var $elm_community$easing_functions$Ease$inQuart = function (time) {
	return A2($elm$core$Basics$pow, time, 4);
};
var $elm_community$easing_functions$Ease$outQuart = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuart);
var $elm_community$easing_functions$Ease$inOutQuart = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuart, $elm_community$easing_functions$Ease$outQuart);
var $elm_community$easing_functions$Ease$inQuint = function (time) {
	return A2($elm$core$Basics$pow, time, 5);
};
var $elm_community$easing_functions$Ease$outQuint = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuint);
var $elm_community$easing_functions$Ease$inOutQuint = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuint, $elm_community$easing_functions$Ease$outQuint);
var $elm_community$easing_functions$Ease$outSine = function (time) {
	return $elm$core$Basics$sin(time * ($elm$core$Basics$pi / 2));
};
var $elm_community$easing_functions$Ease$inSine = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outSine);
var $elm_community$easing_functions$Ease$inOutSine = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inSine, $elm_community$easing_functions$Ease$outSine);
var $elm_community$easing_functions$Ease$linear = $elm$core$Basics$identity;
var $author$project$Shared$Easing$toFunction = function (easing) {
	switch (easing.$) {
		case 9:
			var p1x = easing.a;
			var p1y = easing.b;
			var p2x = easing.c;
			var p2y = easing.d;
			return A4($elm_community$easing_functions$Ease$bezier, p1x, p1y, p2x, p2y);
		case 23:
			return $elm_community$easing_functions$Ease$linear;
		case 13:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 14:
			return $elm_community$easing_functions$Ease$inQuad;
		case 15:
			return $elm_community$easing_functions$Ease$outQuad;
		case 16:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 33:
			return $elm_community$easing_functions$Ease$inSine;
		case 34:
			return $elm_community$easing_functions$Ease$outSine;
		case 35:
			return $elm_community$easing_functions$Ease$inOutSine;
		case 24:
			return $elm_community$easing_functions$Ease$inQuad;
		case 25:
			return $elm_community$easing_functions$Ease$outQuad;
		case 26:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 10:
			return $elm_community$easing_functions$Ease$inCubic;
		case 11:
			return $elm_community$easing_functions$Ease$outCubic;
		case 12:
			return $elm_community$easing_functions$Ease$inOutCubic;
		case 27:
			return $elm_community$easing_functions$Ease$inQuart;
		case 28:
			return $elm_community$easing_functions$Ease$outQuart;
		case 29:
			return $elm_community$easing_functions$Ease$inOutQuart;
		case 30:
			return $elm_community$easing_functions$Ease$inQuint;
		case 31:
			return $elm_community$easing_functions$Ease$outQuint;
		case 32:
			return $elm_community$easing_functions$Ease$inOutQuint;
		case 20:
			return $elm_community$easing_functions$Ease$inExpo;
		case 21:
			return $elm_community$easing_functions$Ease$outExpo;
		case 22:
			return $elm_community$easing_functions$Ease$inOutExpo;
		case 6:
			return $elm_community$easing_functions$Ease$inCirc;
		case 7:
			return $elm_community$easing_functions$Ease$outCirc;
		case 8:
			return $elm_community$easing_functions$Ease$inOutCirc;
		case 0:
			return $elm_community$easing_functions$Ease$inBack;
		case 1:
			return $elm_community$easing_functions$Ease$outBack;
		case 2:
			return $elm_community$easing_functions$Ease$inOutBack;
		case 17:
			return $elm_community$easing_functions$Ease$inElastic;
		case 18:
			return $elm_community$easing_functions$Ease$outElastic;
		case 19:
			return $elm_community$easing_functions$Ease$inOutElastic;
		case 3:
			return $elm_community$easing_functions$Ease$inBounce;
		case 4:
			return $elm_community$easing_functions$Ease$outBounce;
		default:
			return $elm_community$easing_functions$Ease$inOutBounce;
	}
};
var $author$project$Anim$Internal$Engine$Sub$Generator$toAnimation = F2(
	function (isComplete, propertyConfig) {
		var snapped = _Utils_eq(
			$author$project$Anim$Internal$Builder$processedPropertyMode(propertyConfig),
			$author$project$Anim$Internal$Builder$Snap);
		var completeFlag = isComplete || snapped;
		var build = F2(
			function (_default, config) {
				var resolvedStart = A2($elm$core$Maybe$withDefault, _default, config.bw);
				var durationMs = config.v;
				var easingFn = function () {
					var _v1 = config.bv;
					if (!_v1.$) {
						var s = _v1.a;
						return A2($author$project$Anim$Internal$Engine$Sub$Generator$springEasingFunction, s, durationMs);
					} else {
						return $author$project$Shared$Easing$toFunction(config.bQ);
					}
				}();
				return {
					cO: config.s,
					er: easingFn,
					M: snapped ? (durationMs + config.s) : 0.0,
					m: config.m,
					A: completeFlag,
					bw: resolvedStart,
					K: durationMs
				};
			});
		switch (propertyConfig.$) {
			case 0:
				var cssName = propertyConfig.a;
				var unit = propertyConfig.b;
				var config = propertyConfig.c;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'custom:' + cssName,
						A3(
							$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
							cssName,
							unit,
							A2(build, 0, config))));
			case 1:
				var cssName = propertyConfig.a;
				var config = propertyConfig.b;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'customColor:' + cssName,
						A2(
							$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
							cssName,
							A2(
								build,
								$author$project$Anim$Internal$Extra$Color$fromRGB(
									{cI: 0, cV: 0, dn: 0}),
								config))));
			case 2:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'opacity',
						$author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
							A2(build, $author$project$Anim$Internal$Property$Opacity$default, config))));
			case 3:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'perspectiveOrigin',
						A2(
							$author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin,
							config.z,
							A2(build, $author$project$Anim$Internal$Property$PerspectiveOrigin$default, config))));
			case 4:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'rotate',
						$author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
							A2(build, $author$project$Anim$Internal$Property$Rotate$default, config))));
			case 5:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'scale',
						$author$project$Anim$Internal$Engine$Sub$Animation$Scale(
							A2(build, $author$project$Anim$Internal$Property$Scale$default, config))));
			case 6:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'size',
						A2(
							$author$project$Anim$Internal$Engine$Sub$Animation$Size,
							config.z,
							A2(build, $author$project$Anim$Internal$Property$Size$default, config))));
			case 7:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'skew',
						$author$project$Anim$Internal$Engine$Sub$Animation$Skew(
							A2(build, $author$project$Anim$Internal$Property$Skew$default, config))));
			default:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'translate',
						A2(
							$author$project$Anim$Internal$Engine$Sub$Animation$Translate,
							config.z,
							A2(build, $author$project$Anim$Internal$Property$Translate$default, config))));
		}
	});
var $author$project$Anim$Internal$Builder$cssNamesComposite = function (prop) {
	switch (prop.$) {
		case 0:
			var cssName = prop.a;
			return _List_fromArray(
				[cssName]);
		case 1:
			var cssName = prop.a;
			return _List_fromArray(
				[cssName]);
		case 2:
			return _List_fromArray(
				['opacity']);
		case 3:
			return _List_fromArray(
				['perspective-origin']);
		case 4:
			return _List_fromArray(
				['transform']);
		case 5:
			return _List_fromArray(
				['transform']);
		case 6:
			return _List_fromArray(
				['width', 'height']);
		case 7:
			return _List_fromArray(
				['transform']);
		default:
			return _List_fromArray(
				['transform']);
	}
};
var $elm$core$Set$Set_elm_builtin = $elm$core$Basics$identity;
var $elm$core$Set$empty = $elm$core$Dict$empty;
var $elm$core$Set$insert = F2(
	function (key, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, key, 0, dict);
	});
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (!_v0.$) {
			return true;
		} else {
			return false;
		}
	});
var $elm$core$Set$member = F2(
	function (key, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$member, key, dict);
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $author$project$Anim$Internal$Builder$dedupePreservingOrder = A2(
	$elm$core$Basics$composeR,
	A2(
		$elm$core$List$foldl,
		F2(
			function (name, _v0) {
				var seen = _v0.a;
				var acc = _v0.b;
				return A2($elm$core$Set$member, name, seen) ? _Utils_Tuple2(seen, acc) : _Utils_Tuple2(
					A2($elm$core$Set$insert, name, seen),
					A2($elm$core$List$cons, name, acc));
			}),
		_Utils_Tuple2($elm$core$Set$empty, _List_Nil)),
	A2($elm$core$Basics$composeR, $elm$core$Tuple$second, $elm$core$List$reverse));
var $author$project$Anim$Internal$Builder$toWillChangeString = F2(
	function (toNames, props) {
		return A2(
			$elm$core$String$join,
			', ',
			$author$project$Anim$Internal$Builder$dedupePreservingOrder(
				A2($elm$core$List$concatMap, toNames, props)));
	});
var $author$project$Anim$Internal$Builder$willChangeComposite = $author$project$Anim$Internal$Builder$toWillChangeString($author$project$Anim$Internal$Builder$cssNamesComposite);
var $author$project$Anim$Internal$Engine$Sub$Generator$generateAnimation = F7(
	function (iterationCount, directionConfig, maybeOrder, discreteEntryProps, discreteExitProps, existingAnimation, properties) {
		var transformOrder = function () {
			if (!maybeOrder.$) {
				var order = maybeOrder.a;
				return order;
			} else {
				return A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Extra$TransformOrder$default,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder, existingAnimation));
			}
		}();
		var adjustedProperties = A2(
			$elm$core$List$map,
			$author$project$Anim$Internal$Engine$Sub$Generator$scaleInterruptDuration(existingAnimation),
			properties);
		var animations = $author$project$Anim$Internal$Engine$Sub$Animations$fromList(
			A2(
				$elm$core$List$filterMap,
				$author$project$Anim$Internal$Engine$Sub$Generator$toAnimation(false),
				adjustedProperties));
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$setWillChange,
			$author$project$Anim$Internal$Builder$willChangeComposite(adjustedProperties),
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit,
				discreteExitProps,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry,
					discreteEntryProps,
					A2(
						$author$project$Anim$Internal$Engine$Sub$AnimGroup$setTransformOrder,
						transformOrder,
						A2(
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration,
							1,
							A2(
								$author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimationDirection,
								directionConfig,
								A2(
									$author$project$Anim$Internal$Engine$Sub$AnimGroup$setIterationCount,
									iterationCount,
									A2(
										$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
										1,
										A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, animations, $author$project$Anim$Internal$Engine$Sub$AnimGroup$init)))))))));
	});
var $author$project$Anim$Internal$Builder$getAnimGroupConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.y);
	});
var $author$project$Anim$Internal$Builder$getDiscreteEntryProperties = function (_v0) {
	var data = _v0;
	return data.b.e;
};
var $author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor = F2(
	function (animGroupName, builder) {
		var _v0 = A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder);
		if (!_v0.$) {
			var config = _v0.a;
			return A2(
				$elm$core$Maybe$withDefault,
				$author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder),
				A2($elm$core$Maybe$map, $elm$core$Basics$identity, config.e));
		} else {
			return $author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder);
		}
	});
var $author$project$Anim$Internal$Builder$getDiscreteExitProperties = function (_v0) {
	var data = _v0;
	return data.b.f;
};
var $author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor = F2(
	function (animGroupName, builder) {
		var _v0 = A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder);
		if (!_v0.$) {
			var config = _v0.a;
			return A2(
				$elm$core$Maybe$withDefault,
				$author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder),
				A2($elm$core$Maybe$map, $elm$core$Basics$identity, config.f));
		} else {
			return $author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder);
		}
	});
var $elm$core$Dict$map = F2(
	function (func, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				A2(func, key, value),
				A2($elm$core$Dict$map, func, left),
				A2($elm$core$Dict$map, func, right));
		}
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$map = F2(
	function (f, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$map, f, dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PropertyBaselines = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Builder$PropertyBaselines$merge = F2(
	function (_v0, _v1) {
		var base = _v0;
		var override = _v1;
		return A2($elm$core$Dict$union, override, base);
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict = function (_v0) {
	var dict = _v0;
	return dict;
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$merge = F6(
	function (leftStep, bothStep, rightStep, dictB, dictC, _v0) {
		var dictA = _v0;
		return A6(
			$elm$core$Dict$merge,
			F2(
				function (k, b) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A2(leftStep, k, b),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			F3(
				function (k, b, c) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A3(bothStep, k, b, c),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			F2(
				function (k, c) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A2(rightStep, k, c),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			dictB,
			dictC,
			dictA);
	});
var $author$project$Anim$Internal$Builder$injectCurrentStates = F2(
	function (animGroups, _v0) {
		var data = _v0;
		var state = data.u;
		var runtimeSnapshots = A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (_v1, animation) {
					return animation.fe;
				}),
			animGroups);
		var mergedRuntimeBaselines = A6(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$merge,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
			F3(
				function (key, _new, old) {
					return A2(
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
						key,
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$merge, old, _new));
				}),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(runtimeSnapshots),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.Q),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
		return _Utils_update(
			data,
			{
				u: _Utils_update(
					state,
					{b1: mergedRuntimeBaselines})
			});
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$empty = $elm$core$Dict$empty;
var $author$project$Anim$Unit$Percent = 28;
var $author$project$Anim$Unit$Px = 30;
var $author$project$Anim$Internal$Unit$default = 30;
var $author$project$Anim$Internal$Unit$emptyCssUnitAxes = {ao: $elm$core$Maybe$Nothing, ap: $elm$core$Maybe$Nothing, aq: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$extractPerspectiveOriginCssUnit = function (propConfig) {
	if (propConfig.$ === 3) {
		var cfg = propConfig.a;
		return cfg.z;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
var $author$project$Anim$Internal$Builder$extractSizeCssUnit = function (propConfig) {
	if (propConfig.$ === 6) {
		var cfg = propConfig.a;
		return cfg.z;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
var $author$project$Anim$Internal$Builder$extractTranslateCssUnit = function (propConfig) {
	if (propConfig.$ === 8) {
		var cfg = propConfig.a;
		return cfg.z;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
var $author$project$Anim$Internal$Unit$orMaybe = F2(
	function (primary, fallback) {
		if (!primary.$) {
			return primary;
		} else {
			return fallback;
		}
	});
var $author$project$Anim$Internal$Unit$mergeBaselineUnits = F2(
	function (maybeBaseline, axes) {
		if (maybeBaseline.$ === 1) {
			return axes;
		} else {
			var baseline = maybeBaseline.a;
			return {
				ao: A2($author$project$Anim$Internal$Unit$orMaybe, axes.ao, baseline.ao),
				ap: A2($author$project$Anim$Internal$Unit$orMaybe, axes.ap, baseline.ap),
				aq: A2($author$project$Anim$Internal$Unit$orMaybe, axes.aq, baseline.aq)
			};
		}
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$get = F2(
	function (group, slot) {
		return $elm$core$Dict$get(
			_Utils_Tuple2(group, slot));
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$getAxes = F3(
	function (group, slots, store) {
		return {
			ao: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.ao, store),
			ap: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.ap, store),
			aq: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.aq, store)
		};
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginX = 'perspectiveOrigin.x';
var $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginY = 'perspectiveOrigin.y';
var $author$project$Anim$Internal$Builder$perspectiveOriginStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ao: $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginX, ap: $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginY, aq: ''},
			defaults._);
	});
var $author$project$Anim$Internal$Unit$pickAxis = F3(
	function (local, global, default_) {
		if (!local.$) {
			var unit = local.a;
			return unit;
		} else {
			if (!global.$) {
				var unit = global.a;
				return unit;
			} else {
				return default_;
			}
		}
	});
var $author$project$Anim$Internal$Unit$resolveCssUnitAxes = F3(
	function (local, global, default_) {
		return {
			ao: A3($author$project$Anim$Internal$Unit$pickAxis, local.ao, global.ao, default_),
			ap: A3($author$project$Anim$Internal$Unit$pickAxis, local.ap, global.ap, default_),
			aq: A3($author$project$Anim$Internal$Unit$pickAxis, local.aq, global.aq, default_)
		};
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$CustomColorPropertyValue = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty = F3(
	function (cssPropertyName, value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'customColor:' + cssPropertyName,
			$author$project$Anim$Internal$Builder$PropertyBaselines$CustomColorPropertyValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$CustomPropertyValue = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty = F4(
	function (cssPropertyName, value, unit, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'custom:' + cssPropertyName,
			A2($author$project$Anim$Internal$Builder$PropertyBaselines$CustomPropertyValue, value, unit),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$OpacityValue = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'opacity',
			$author$project$Anim$Internal$Builder$PropertyBaselines$OpacityValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginValue = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'perspectiveOrigin',
			$author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginConfiguredUnitsValue = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginConfiguredUnits = F2(
	function (axes, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'perspectiveOriginConfiguredUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginConfiguredUnitsValue(axes),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginUnitsValue = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits = F2(
	function (units, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'perspectiveOriginUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginUnitsValue(units),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$RotateValue = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'rotate',
			$author$project$Anim$Internal$Builder$PropertyBaselines$RotateValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$ScaleValue = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setScale = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'scale',
			$author$project$Anim$Internal$Builder$PropertyBaselines$ScaleValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SizeValue = function (a) {
	return {$: 8, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSize = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'size',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SizeValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SizeConfiguredUnitsValue = function (a) {
	return {$: 10, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSizeConfiguredUnits = F2(
	function (axes, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'sizeConfiguredUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SizeConfiguredUnitsValue(axes),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SizeUnitsValue = function (a) {
	return {$: 9, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits = F2(
	function (units, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'sizeUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SizeUnitsValue(units),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SkewValue = function (a) {
	return {$: 11, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'skew',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SkewValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$TranslateValue = function (a) {
	return {$: 12, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'translate',
			$author$project$Anim$Internal$Builder$PropertyBaselines$TranslateValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$TranslateConfiguredUnitsValue = function (a) {
	return {$: 14, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateConfiguredUnits = F2(
	function (axes, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'translateConfiguredUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$TranslateConfiguredUnitsValue(axes),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$TranslateUnitsValue = function (a) {
	return {$: 13, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits = F2(
	function (units, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'translateUnits',
			$author$project$Anim$Internal$Builder$PropertyBaselines$TranslateUnitsValue(units),
			dict);
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$sizeHeight = 'size.height';
var $author$project$Anim$Internal$Builder$CssUnitStore$sizeWidth = 'size.width';
var $author$project$Anim$Internal$Builder$sizeStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ao: $author$project$Anim$Internal$Builder$CssUnitStore$sizeWidth, ap: $author$project$Anim$Internal$Builder$CssUnitStore$sizeHeight, aq: ''},
			defaults._);
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$translateX = 'translate.x';
var $author$project$Anim$Internal$Builder$CssUnitStore$translateY = 'translate.y';
var $author$project$Anim$Internal$Builder$CssUnitStore$translateZ = 'translate.z';
var $author$project$Anim$Internal$Builder$translateStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ao: $author$project$Anim$Internal$Builder$CssUnitStore$translateX, ap: $author$project$Anim$Internal$Builder$CssUnitStore$translateY, aq: $author$project$Anim$Internal$Builder$CssUnitStore$translateZ},
			defaults._);
	});
var $author$project$Anim$Internal$Builder$extractPropertyBaseline = F4(
	function (defaults, animGroupName, propConfig, baselines) {
		var translateUnits = function (_v3) {
			return A2(
				$author$project$Anim$Internal$Unit$mergeBaselineUnits,
				$elm$core$Maybe$Just(
					A2($author$project$Anim$Internal$Builder$translateStoreAxes, defaults, animGroupName)),
				$author$project$Anim$Internal$Builder$extractTranslateCssUnit(propConfig));
		};
		var sizeUnits = function (_v2) {
			return A2(
				$author$project$Anim$Internal$Unit$mergeBaselineUnits,
				$elm$core$Maybe$Just(
					A2($author$project$Anim$Internal$Builder$sizeStoreAxes, defaults, animGroupName)),
				$author$project$Anim$Internal$Builder$extractSizeCssUnit(propConfig));
		};
		var perspectiveOriginUnits = function (_v1) {
			return A2(
				$author$project$Anim$Internal$Unit$mergeBaselineUnits,
				$elm$core$Maybe$Just(
					A2($author$project$Anim$Internal$Builder$perspectiveOriginStoreAxes, defaults, animGroupName)),
				$author$project$Anim$Internal$Builder$extractPerspectiveOriginCssUnit(propConfig));
		};
		switch (propConfig.$) {
			case 8:
				var cfg = propConfig.a;
				var merged = translateUnits(0);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateConfiguredUnits,
					merged,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits,
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.h, $author$project$Anim$Internal$Unit$default),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, cfg.m, baselines)));
			case 4:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, cfg.m, baselines);
			case 5:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, cfg.m, baselines);
			case 7:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, cfg.m, baselines);
			case 2:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, cfg.m, baselines);
			case 3:
				var cfg = propConfig.a;
				var merged = perspectiveOriginUnits(0);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginConfiguredUnits,
					merged,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.h, 28),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, cfg.m, baselines)));
			case 6:
				var cfg = propConfig.a;
				var merged = sizeUnits(0);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeConfiguredUnits,
					merged,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.W, $author$project$Anim$Internal$Unit$default),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, cfg.m, baselines)));
			case 0:
				var cssName = propConfig.a;
				var unit = propConfig.b;
				var cfg = propConfig.c;
				return A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, cfg.m, unit, baselines);
			default:
				var cssName = propConfig.a;
				var cfg = propConfig.b;
				return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, cfg.m, baselines);
		}
	});
var $author$project$Anim$Internal$Builder$extractBaselinesFromConfig = F3(
	function (defaults, animGroupName, elementConfig) {
		return A3(
			$elm$core$List$foldl,
			A2($author$project$Anim$Internal$Builder$extractPropertyBaseline, defaults, animGroupName),
			$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
			elementConfig.q);
	});
var $author$project$Anim$Internal$Builder$mergeBaselines = function (_v0) {
	var data = _v0;
	var defaults = data.c;
	var animation = data.a;
	var state = data.u;
	var mergeBoth = F3(
		function (key, _new, old) {
			return A2(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				key,
				A2($author$project$Anim$Internal$Builder$PropertyBaselines$merge, old, _new));
		});
	var getDefaultsForGroup = function (groupName) {
		return A2(
			$elm$core$Maybe$withDefault,
			defaults,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, groupName, animation.U));
	};
	var newBaselines = A2(
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
		F2(
			function (groupName, config) {
				return A3(
					$author$project$Anim$Internal$Builder$extractBaselinesFromConfig,
					getDefaultsForGroup(groupName),
					groupName,
					config);
			}),
		animation.y);
	var newState = _Utils_update(
		state,
		{
			Q: A6(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$merge,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				mergeBoth,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(newBaselines),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.Q),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$init)
		});
	return _Utils_update(
		data,
		{u: newState});
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$names = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedRotateConfig = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedScaleConfig = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedSizeConfig = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedSkewConfig = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedTranslateConfig = function (a) {
	return {$: 8, a: a};
};
var $author$project$Anim$Internal$Extra$Color$cleanHex = function (hex_) {
	return A2($elm$core$String$startsWith, '#', hex_) ? A2($elm$core$String$dropLeft, 1, hex_) : hex_;
};
var $elm$core$String$fromList = _String_fromList;
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $author$project$Anim$Internal$Extra$Color$expandHex = function (hex_) {
	return ($elm$core$String$length(hex_) === 3) ? $elm$core$String$fromList(
		A2(
			$elm$core$List$concatMap,
			function (c) {
				return _List_fromArray(
					[c, c]);
			},
			$elm$core$String$toList(hex_))) : hex_;
};
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 1) {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $author$project$Anim$Internal$Extra$Color$hexToInt = function (str) {
	var hexCharToInt = function (_char) {
		switch (_char) {
			case '0':
				return $elm$core$Maybe$Just(0);
			case '1':
				return $elm$core$Maybe$Just(1);
			case '2':
				return $elm$core$Maybe$Just(2);
			case '3':
				return $elm$core$Maybe$Just(3);
			case '4':
				return $elm$core$Maybe$Just(4);
			case '5':
				return $elm$core$Maybe$Just(5);
			case '6':
				return $elm$core$Maybe$Just(6);
			case '7':
				return $elm$core$Maybe$Just(7);
			case '8':
				return $elm$core$Maybe$Just(8);
			case '9':
				return $elm$core$Maybe$Just(9);
			case 'A':
				return $elm$core$Maybe$Just(10);
			case 'a':
				return $elm$core$Maybe$Just(10);
			case 'B':
				return $elm$core$Maybe$Just(11);
			case 'b':
				return $elm$core$Maybe$Just(11);
			case 'C':
				return $elm$core$Maybe$Just(12);
			case 'c':
				return $elm$core$Maybe$Just(12);
			case 'D':
				return $elm$core$Maybe$Just(13);
			case 'd':
				return $elm$core$Maybe$Just(13);
			case 'E':
				return $elm$core$Maybe$Just(14);
			case 'e':
				return $elm$core$Maybe$Just(14);
			case 'F':
				return $elm$core$Maybe$Just(15);
			case 'f':
				return $elm$core$Maybe$Just(15);
			default:
				return $elm$core$Maybe$Nothing;
		}
	};
	var chars = $elm$core$String$toList(str);
	if ((chars.b && chars.b.b) && (!chars.b.b.b)) {
		var c1 = chars.a;
		var _v1 = chars.b;
		var c2 = _v1.a;
		return A3(
			$elm$core$Maybe$map2,
			F2(
				function (v1, v2) {
					return (v1 * 16) + v2;
				}),
			hexCharToInt(c1),
			hexCharToInt(c2));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Anim$Internal$Extra$Color$hexByteAt = F3(
	function (start, _default, hex_) {
		return A2(
			$elm$core$Maybe$withDefault,
			_default,
			$author$project$Anim$Internal$Extra$Color$hexToInt(
				A3($elm$core$String$slice, start, start + 2, hex_)));
	});
var $author$project$Anim$Internal$Extra$Color$hexToRgb = function (hex_) {
	var cleanHex_ = $author$project$Anim$Internal$Extra$Color$expandHex(
		$author$project$Anim$Internal$Extra$Color$cleanHex(hex_));
	var g = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 2, 0, cleanHex_);
	var r = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 0, 0, cleanHex_);
	var b = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 4, 0, cleanHex_);
	return {cI: b, cV: g, dn: r};
};
var $author$project$Anim$Internal$Extra$Color$floatMod = F2(
	function (a, b) {
		return a - ($elm$core$Basics$floor(a / b) * b);
	});
var $author$project$Anim$Internal$Extra$Color$hslToRgb = function (hslValue) {
	var s = hslValue.dq / 100;
	var l = hslValue.c2 / 100;
	var c = (1 - $elm$core$Basics$abs((2 * l) - 1)) * s;
	var m = l - (c / 2);
	var x = c * (1 - $elm$core$Basics$abs(
		A2($author$project$Anim$Internal$Extra$Color$floatMod, hslValue.cW / 60, 2) - 1));
	var _v0 = (hslValue.cW < 60) ? _Utils_Tuple3(c, x, 0) : ((hslValue.cW < 120) ? _Utils_Tuple3(x, c, 0) : ((hslValue.cW < 180) ? _Utils_Tuple3(0, c, x) : ((hslValue.cW < 240) ? _Utils_Tuple3(0, x, c) : ((hslValue.cW < 300) ? _Utils_Tuple3(x, 0, c) : _Utils_Tuple3(c, 0, x)))));
	var r1 = _v0.a;
	var g1 = _v0.b;
	var b1 = _v0.c;
	var b = $elm$core$Basics$round((b1 + m) * 255);
	var g = $elm$core$Basics$round((g1 + m) * 255);
	var r = $elm$core$Basics$round((r1 + m) * 255);
	return {cI: b, cV: g, dn: r};
};
var $avh4$elm_color$Color$toRgba = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	return {bG: a, cg: b, cn: g, cw: r};
};
var $author$project$Anim$Internal$Extra$Color$toRgb = function (color) {
	switch (color.$) {
		case 0:
			var hex_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hexToRgb(hex_);
		case 1:
			var rgb_ = color.a;
			return rgb_;
		case 2:
			var rgba_ = color.a;
			return {cI: rgba_.cI, cV: rgba_.cV, dn: rgba_.dn};
		case 3:
			var hsl_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(hsl_);
		case 4:
			var hsla_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(
				{cW: hsla_.cW, c2: hsla_.c2, dq: hsla_.dq});
		default:
			var elmColor_ = color.a;
			var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
			return {
				cI: $elm$core$Basics$round(rgba_.cg * 255),
				cV: $elm$core$Basics$round(rgba_.cn * 255),
				dn: $elm$core$Basics$round(rgba_.cw * 255)
			};
	}
};
var $author$project$Anim$Internal$Extra$Color$distance = F2(
	function (color1, color2) {
		var rgb2 = $author$project$Anim$Internal$Extra$Color$toRgb(color2);
		var rgb1 = $author$project$Anim$Internal$Extra$Color$toRgb(color1);
		var dr = rgb2.dn - rgb1.dn;
		var dg = rgb2.cV - rgb1.cV;
		var db = rgb2.cI - rgb1.cI;
		return $elm$core$Basics$sqrt(((dr * dr) + (dg * dg)) + (db * db));
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple = function (_v0) {
	var y = _v0.ap;
	var x = _v0.ao;
	return _Utils_Tuple2(x, y);
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$distance = F2(
	function (start, end) {
		var _v0 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(start);
		var sx = _v0.a;
		var sy = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(end);
		var ex = _v1.a;
		var ey = _v1.b;
		var dx = ex - sx;
		var dy = ey - sy;
		return $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$distance = F3(
	function (support, coord1, coord2) {
		var record2 = support.fV(coord2);
		var record1 = support.fV(coord1);
		var dz = $elm$core$Basics$abs(record2.aq - record1.aq);
		var dy = $elm$core$Basics$abs(record2.ap - record1.ap);
		var dx = $elm$core$Basics$abs(record2.ao - record1.ao);
		return A2(
			$elm$core$Basics$max,
			dx,
			A2($elm$core$Basics$max, dy, dz));
	});
var $author$project$Anim$Internal$Property$Rotate$support = {
	dG: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ao: a.ao + b.ao, ap: a.ap + b.ap, aq: a.aq + b.aq};
		}),
	ek: $author$project$Anim$Internal$Property$Rotate$default,
	eB: $elm$core$Basics$identity,
	b2: F2(
		function (factor, _v2) {
			var angles = _v2;
			return {ao: angles.ao * factor, ap: angles.ap * factor, aq: angles.aq * factor};
		}),
	fC: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ao: a.ao - b.ao, ap: a.ap - b.ap, aq: a.aq - b.aq};
		}),
	fV: function (_v5) {
		var angles = _v5;
		return angles;
	}
};
var $author$project$Anim$Internal$Property$Rotate$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Property$Scale$support = {
	dG: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ao: a.ao + b.ao, ap: a.ap + b.ap, aq: a.aq + b.aq};
		}),
	ek: $author$project$Anim$Internal$Property$Scale$default,
	eB: $elm$core$Basics$identity,
	b2: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {ao: coords.ao * factor, ap: coords.ap * factor, aq: coords.aq * factor};
		}),
	fC: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ao: a.ao - b.ao, ap: a.ap - b.ap, aq: a.aq - b.aq};
		}),
	fV: function (_v5) {
		var coords = _v5;
		return coords;
	}
};
var $author$project$Anim$Internal$Property$Scale$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Size$distance = F2(
	function (_v0, _v1) {
		var start = _v0;
		var end = _v1;
		var dw = end.P - start.P;
		var dh = end.cW - start.cW;
		return $elm$core$Basics$sqrt((dw * dw) + (dh * dh));
	});
var $author$project$Anim$Internal$Property$Skew$toTuple = function (_v0) {
	var values = _v0;
	return _Utils_Tuple2(values.ao, values.ap);
};
var $author$project$Anim$Internal$Property$Skew$distance = F2(
	function (start, end) {
		var _v0 = $author$project$Anim$Internal$Property$Skew$toTuple(start);
		var startX = _v0.a;
		var startY = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$Skew$toTuple(end);
		var endX = _v1.a;
		var endY = _v1.b;
		var dx = endX - startX;
		var dy = endY - startY;
		return $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
	});
var $author$project$Anim$Internal$Property$Translate$support = {
	dG: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ao: a.ao + b.ao, ap: a.ap + b.ap, aq: a.aq + b.aq};
		}),
	ek: $author$project$Anim$Internal$Property$Translate$default,
	eB: $elm$core$Basics$identity,
	b2: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {ao: coords.ao * factor, ap: coords.ap * factor, aq: coords.aq * factor};
		}),
	fC: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ao: a.ao - b.ao, ap: a.ap - b.ap, aq: a.aq - b.aq};
		}),
	fV: function (_v5) {
		var coords = _v5;
		return coords;
	}
};
var $author$project$Anim$Internal$Property$Translate$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Shared$TimeSpec$duration = F2(
	function (distance, timeSpec) {
		if (!timeSpec.$) {
			var ms = timeSpec.a;
			return ms;
		} else {
			var unitsPerSecond = timeSpec.a;
			return (!unitsPerSecond) ? 0 : ((distance / unitsPerSecond) * 1000);
		}
	});
var $author$project$Anim$Internal$Extra$Color$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Opacity$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Rotate$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Scale$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Size$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Skew$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Translate$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Opacity$fromFloat = function (o) {
	return o;
};
var $author$project$Shared$TimeSpec$Duration = function (a) {
	return {$: 0, a: a};
};
var $author$project$Motion$Easing$EaseInOut = {$: 16};
var $author$project$Anim$Internal$Builder$resolveMaybeWithDefault = F3(
	function (local, global, _default) {
		var _v0 = _Utils_Tuple2(local, global);
		if (!_v0.a.$) {
			var value = _v0.a.a;
			return value;
		} else {
			if (!_v0.b.$) {
				var _v1 = _v0.a;
				var value = _v0.b.a;
				return value;
			} else {
				var _v2 = _v0.a;
				var _v3 = _v0.b;
				return _default;
			}
		}
	});
var $author$project$Anim$Internal$Builder$resolveDelayWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $author$project$Anim$Internal$Builder$resolveEasingWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $author$project$Anim$Internal$Builder$resolveTimingWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Shared$Spring$settleTimeS = function (sol) {
	var epsilon = 0.005;
	var cap = 300.0;
	switch (sol.$) {
		case 0:
			var b = sol.a.cI;
			var a = sol.a.cE;
			var zeta = sol.a.bF;
			var omega0 = sol.a.ah;
			if ((zeta * omega0) <= 0) {
				return cap;
			} else {
				var envMax = $elm$core$Basics$sqrt((a * a) + (b * b));
				return (_Utils_cmp(envMax, epsilon) < 1) ? 0.0 : A2(
					$elm$core$Basics$min,
					cap,
					A2($elm$core$Basics$logBase, $elm$core$Basics$e, envMax / epsilon) / (zeta * omega0));
			}
		case 1:
			var b = sol.a.cI;
			var a = sol.a.cE;
			var omega0 = sol.a.ah;
			if (omega0 <= 0) {
				return cap;
			} else {
				var envMax = $elm$core$Basics$abs(a) + ($elm$core$Basics$abs(b) / omega0);
				return (_Utils_cmp(envMax, epsilon) < 1) ? 0.0 : A2(
					$elm$core$Basics$min,
					cap,
					A2($elm$core$Basics$logBase, $elm$core$Basics$e, envMax / epsilon) / omega0);
			}
		default:
			var b = sol.a.cI;
			var a = sol.a.cE;
			var r2 = sol.a.bu;
			var r1 = sol.a.bt;
			var _v1 = (_Utils_cmp(
				$elm$core$Basics$abs(r1),
				$elm$core$Basics$abs(r2)) < 0) ? _Utils_Tuple2(r1, a) : _Utils_Tuple2(r2, b);
			var slowR = _v1.a;
			var slowCoef = _v1.b;
			return ((slowR >= 0) || (_Utils_cmp(
				$elm$core$Basics$abs(slowCoef),
				epsilon) < 1)) ? cap : A2(
				$elm$core$Basics$min,
				cap,
				A2(
					$elm$core$Basics$logBase,
					$elm$core$Basics$e,
					$elm$core$Basics$abs(slowCoef) / epsilon) / $elm$core$Basics$abs(slowR));
	}
};
var $author$project$Shared$Spring$settleTimeMs = function (params) {
	return $author$project$Shared$Spring$settleTimeS(
		$author$project$Shared$Spring$precompute(params)) * 1000.0;
};
var $author$project$Anim$Internal$Builder$processStandardAnimation = function (_v0) {
	var wrapper = _v0.an;
	var speedFn = _v0.al;
	var durationFn = _v0.ad;
	var distanceFn = _v0.ac;
	var defaultCssUnit = _v0.aa;
	var defaultStart = _v0.ab;
	var globalCssUnit = _v0.h;
	var globalData = _v0.ae;
	var config = _v0.E;
	var start = A2($elm$core$Maybe$withDefault, defaultStart, config.bw);
	var resolvedTiming = A3(
		$author$project$Anim$Internal$Builder$resolveTimingWithDefault,
		config.b6,
		globalData.af,
		$author$project$Shared$TimeSpec$Duration(0));
	var resolvedSpring = config.bv;
	var distance_ = A2(distanceFn, start, config.m);
	var rawDuration = A2(durationFn, distance_, resolvedTiming);
	var duration_ = function () {
		if (!resolvedSpring.$) {
			var s = resolvedSpring.a;
			return $author$project$Shared$Spring$settleTimeMs(
				{
					bR: 0,
					bv: $author$project$Motion$Internal$Spring$unwrap(s),
					b7: 1
				});
		} else {
			return rawDuration;
		}
	}();
	var speed_ = A3(speedFn, distance_, duration_, resolvedTiming);
	return wrapper(
		{
			z: A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, config.z, globalCssUnit, defaultCssUnit),
			s: A3($author$project$Anim$Internal$Builder$resolveDelayWithDefault, config.s, $elm$core$Maybe$Nothing, 0),
			cl: distance_,
			v: $elm$core$Basics$round(duration_),
			bQ: A3($author$project$Anim$Internal$Builder$resolveEasingWithDefault, config.bQ, $elm$core$Maybe$Nothing, $author$project$Motion$Easing$EaseInOut),
			m: config.m,
			O: config.O,
			du: speed_,
			bv: resolvedSpring,
			bw: config.bw,
			b6: resolvedTiming
		});
};
var $author$project$Shared$TimeSpec$speed = F3(
	function (distance_, duration_, timeSpec) {
		if (!timeSpec.$) {
			var ms = timeSpec.a;
			return (ms <= 0) ? ((distance_ * duration_) * 1000) : (distance_ / (ms / 1000));
		} else {
			var unitsPerSecond = timeSpec.a;
			return unitsPerSecond;
		}
	});
var $author$project$Anim$Internal$Extra$Color$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Opacity$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Rotate$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Scale$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Size$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Skew$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Translate$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Extra$Color$Rgba = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Extra$Color$transparent = $author$project$Anim$Internal$Extra$Color$Rgba(
	{cE: 0, cI: 255, cV: 255, dn: 255});
var $author$project$Anim$Internal$Builder$processProperty = F3(
	function (globalData, animGroupName, property) {
		var mergeTranslate = function (cfg) {
			return _Utils_update(
				cfg,
				{
					z: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$translateStoreAxes, globalData, animGroupName)),
						cfg.z)
				});
		};
		var mergeSize = function (cfg) {
			return _Utils_update(
				cfg,
				{
					z: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$sizeStoreAxes, globalData, animGroupName)),
						cfg.z)
				});
		};
		var mergePerspectiveOrigin = function (cfg) {
			return _Utils_update(
				cfg,
				{
					z: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$perspectiveOriginStoreAxes, globalData, animGroupName)),
						cfg.z)
				});
		};
		switch (property.$) {
			case 0:
				var cssName = property.a;
				var unit = property.b;
				var config = property.c;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: config,
							aa: $author$project$Anim$Internal$Unit$default,
							ab: 0,
							ac: F2(
								function (a, b) {
									return $elm$core$Basics$abs(b - a);
								}),
							ad: $author$project$Shared$TimeSpec$duration,
							h: globalData.h,
							ae: globalData,
							al: $author$project$Shared$TimeSpec$speed,
							an: A2($author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig, cssName, unit)
						}));
			case 1:
				var cssName = property.a;
				var config = property.b;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: config,
							aa: $author$project$Anim$Internal$Unit$default,
							ab: $author$project$Anim$Internal$Extra$Color$transparent,
							ac: $author$project$Anim$Internal$Extra$Color$distance,
							ad: $author$project$Anim$Internal$Extra$Color$duration,
							h: globalData.h,
							ae: globalData,
							al: $author$project$Anim$Internal$Extra$Color$speed,
							an: $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig(cssName)
						}));
			case 2:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: config,
							aa: $author$project$Anim$Internal$Unit$default,
							ab: $author$project$Anim$Internal$Property$Opacity$fromFloat(1.0),
							ac: $author$project$Anim$Internal$Property$Opacity$distance,
							ad: $author$project$Anim$Internal$Property$Opacity$duration,
							h: globalData.h,
							ae: globalData,
							al: $author$project$Anim$Internal$Property$Opacity$speed,
							an: $author$project$Anim$Internal$Builder$ProcessedOpacityConfig
						}));
			case 3:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: mergePerspectiveOrigin(config),
							aa: 28,
							ab: $author$project$Anim$Internal$Property$PerspectiveOrigin$default,
							ac: $author$project$Anim$Internal$Property$PerspectiveOrigin$distance,
							ad: $author$project$Anim$Internal$Property$PerspectiveOrigin$duration,
							h: globalData.h,
							ae: globalData,
							al: $author$project$Anim$Internal$Property$PerspectiveOrigin$speed,
							an: $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig
						}));
			case 4:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{E: config, aa: $author$project$Anim$Internal$Unit$default, ab: $author$project$Anim$Internal$Property$Rotate$default, ac: $author$project$Anim$Internal$Property$Rotate$distance, ad: $author$project$Anim$Internal$Property$Rotate$duration, h: globalData.h, ae: globalData, al: $author$project$Anim$Internal$Property$Rotate$speed, an: $author$project$Anim$Internal$Builder$ProcessedRotateConfig}));
			case 5:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{E: config, aa: $author$project$Anim$Internal$Unit$default, ab: $author$project$Anim$Internal$Property$Scale$default, ac: $author$project$Anim$Internal$Property$Scale$distance, ad: $author$project$Anim$Internal$Property$Scale$duration, h: globalData.h, ae: globalData, al: $author$project$Anim$Internal$Property$Scale$speed, an: $author$project$Anim$Internal$Builder$ProcessedScaleConfig}));
			case 6:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: mergeSize(config),
							aa: $author$project$Anim$Internal$Unit$default,
							ab: $author$project$Anim$Internal$Property$Size$default,
							ac: $author$project$Anim$Internal$Property$Size$distance,
							ad: $author$project$Anim$Internal$Property$Size$duration,
							h: globalData.W,
							ae: globalData,
							al: $author$project$Anim$Internal$Property$Size$speed,
							an: $author$project$Anim$Internal$Builder$ProcessedSizeConfig
						}));
			case 7:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{E: config, aa: $author$project$Anim$Internal$Unit$default, ab: $author$project$Anim$Internal$Property$Skew$default, ac: $author$project$Anim$Internal$Property$Skew$distance, ad: $author$project$Anim$Internal$Property$Skew$duration, h: globalData.h, ae: globalData, al: $author$project$Anim$Internal$Property$Skew$speed, an: $author$project$Anim$Internal$Builder$ProcessedSkewConfig}));
			default:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							E: mergeTranslate(config),
							aa: $author$project$Anim$Internal$Unit$default,
							ab: $author$project$Anim$Internal$Property$Translate$default,
							ac: $author$project$Anim$Internal$Property$Translate$distance,
							ad: $author$project$Anim$Internal$Property$Translate$duration,
							h: globalData.h,
							ae: globalData,
							al: $author$project$Anim$Internal$Property$Translate$speed,
							an: $author$project$Anim$Internal$Builder$ProcessedTranslateConfig
						}));
		}
	});
var $author$project$Anim$Internal$Builder$processProperties = F2(
	function (defaults, animGroupName) {
		return $elm$core$List$filterMap(
			A2($author$project$Anim$Internal$Builder$processProperty, defaults, animGroupName));
	});
var $author$project$Anim$Internal$Builder$process = function (_v0) {
	var data = _v0;
	var getDefaultsForGroup = function (groupName) {
		return A2(
			$elm$core$Maybe$withDefault,
			data.c,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, groupName, data.a.U));
	};
	return {
		w: data.b.w,
		h: data.c.h,
		aD: data.c.aD,
		at: data.c.at,
		aE: data.c.aE,
		af: data.c.af,
		co: A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (groupName, group) {
					var groupDefaults = getDefaultsForGroup(groupName);
					return {
						e: function () {
							var _v1 = group.e;
							if (!_v1.$) {
								var overrides = _v1.a;
								return overrides;
							} else {
								return data.b.e;
							}
						}(),
						f: function () {
							var _v2 = group.f;
							if (!_v2.$) {
								var overrides = _v2.a;
								return overrides;
							} else {
								return data.b.f;
							}
						}(),
						g: group.g,
						d: function () {
							var _v3 = group.d;
							if (!_v3.$) {
								var axes = _v3.a;
								return axes;
							} else {
								return data.a.d;
							}
						}(),
						b: group.b,
						q: A3($author$project$Anim$Internal$Builder$processProperties, groupDefaults, groupName, group.q),
						o: function () {
							var _v4 = group.o;
							if (!_v4.$) {
								return group.o;
							} else {
								return groupDefaults.aF;
							}
						}(),
						i: A2($elm$core$Maybe$withDefault, data.i, group.i),
						j: group.j,
						k: group.k
					};
				}),
			data.a.y),
		r: data.b.r
	};
};
var $author$project$Anim$Internal$Builder$resolvePlayback = F3(
	function (globalIterations, globalDirection, maybePlayback) {
		if (maybePlayback.$ === 1) {
			return {w: globalDirection, r: globalIterations};
		} else {
			var playback = maybePlayback.a;
			return {
				w: A2($elm$core$Maybe$withDefault, globalDirection, playback.w),
				r: A2($elm$core$Maybe$withDefault, globalIterations, playback.r)
			};
		}
	});
var $author$project$Anim$Internal$Extra$Color$Hsl = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Extra$Color$Hsla = function (a) {
	return {$: 4, a: a};
};
var $elm$core$List$maximum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$max, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$List$minimum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$min, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Anim$Internal$Extra$Color$rgbToHsl = function (rgb_) {
	var r = rgb_.dn / 255;
	var g = rgb_.cV / 255;
	var b = rgb_.cI / 255;
	var maxVal = A2(
		$elm$core$Maybe$withDefault,
		0,
		$elm$core$List$maximum(
			_List_fromArray(
				[r, g, b])));
	var minVal = A2(
		$elm$core$Maybe$withDefault,
		0,
		$elm$core$List$minimum(
			_List_fromArray(
				[r, g, b])));
	var delta = maxVal - minVal;
	var h = (!delta) ? 0 : (_Utils_eq(maxVal, r) ? (60 * A2($author$project$Anim$Internal$Extra$Color$floatMod, (g - b) / delta, 6)) : (_Utils_eq(maxVal, g) ? (60 * (((b - r) / delta) + 2)) : (60 * (((r - g) / delta) + 4))));
	var hNormalized = (h < 0) ? (h + 360) : ((h >= 360) ? (h - 360) : h);
	var l = (maxVal + minVal) / 2;
	var s = (!delta) ? 0 : (delta / (1 - $elm$core$Basics$abs((2 * l) - 1)));
	return {cW: hNormalized, c2: l * 100, dq: s * 100};
};
var $author$project$Anim$Internal$Extra$Color$rgbaToHsla = function (rgba_) {
	var rgb_ = {cI: rgba_.cI, cV: rgba_.cV, dn: rgba_.dn};
	var hsla_ = $author$project$Anim$Internal$Extra$Color$rgbToHsl(rgb_);
	return {cE: rgba_.cE, cW: hsla_.cW, c2: hsla_.c2, dq: hsla_.dq};
};
var $author$project$Anim$Internal$Extra$Color$toHsl = function (color) {
	switch (color.$) {
		case 3:
			var hsl_ = color.a;
			return hsl_;
		case 4:
			var hslaValue = color.a;
			return {cW: hslaValue.cW, c2: hslaValue.c2, dq: hslaValue.dq};
		default:
			return $author$project$Anim$Internal$Extra$Color$rgbToHsl(
				$author$project$Anim$Internal$Extra$Color$toRgb(color));
	}
};
var $author$project$Anim$Internal$Extra$Color$toHsla = function (color) {
	switch (color.$) {
		case 4:
			var hsla_ = color.a;
			return hsla_;
		case 2:
			var rgba_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$rgbaToHsla(rgba_);
		default:
			var hslValue = $author$project$Anim$Internal$Extra$Color$toHsl(color);
			return {cE: 1.0, cW: hslValue.cW, c2: hslValue.c2, dq: hslValue.dq};
	}
};
var $author$project$Anim$Internal$Extra$Color$hexToRgba = function (hex_) {
	var cleanHex_ = $author$project$Anim$Internal$Extra$Color$expandHex(
		$author$project$Anim$Internal$Extra$Color$cleanHex(hex_));
	var rgb_ = $author$project$Anim$Internal$Extra$Color$hexToRgb(cleanHex_);
	var alpha_ = function (a) {
		return a / 255;
	}(
		A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 6, 255, cleanHex_));
	return {cE: alpha_, cI: rgb_.cI, cV: rgb_.cV, dn: rgb_.dn};
};
var $author$project$Anim$Internal$Extra$Color$hslaToRgba = function (hslaValue) {
	var rgb_ = $author$project$Anim$Internal$Extra$Color$hslToRgb(
		{cW: hslaValue.cW, c2: hslaValue.c2, dq: hslaValue.dq});
	return {cE: hslaValue.cE, cI: rgb_.cI, cV: rgb_.cV, dn: rgb_.dn};
};
var $author$project$Anim$Internal$Extra$Color$toRgba = function (color) {
	switch (color.$) {
		case 0:
			var hex_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hexToRgba(hex_);
		case 2:
			var rgba_ = color.a;
			return rgba_;
		case 4:
			var hsla_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslaToRgba(hsla_);
		case 5:
			var elmColor_ = color.a;
			var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
			return {
				cE: rgba_.bG,
				cI: $elm$core$Basics$round(rgba_.cg * 255),
				cV: $elm$core$Basics$round(rgba_.cn * 255),
				dn: $elm$core$Basics$round(rgba_.cw * 255)
			};
		default:
			var rgb_ = $author$project$Anim$Internal$Extra$Color$toRgb(color);
			return {cE: 1.0, cI: rgb_.cI, cV: rgb_.cV, dn: rgb_.dn};
	}
};
var $author$project$Anim$Internal$Extra$Color$interpolate = F3(
	function (t, start, end) {
		interpolate:
		while (true) {
			var _v0 = _Utils_Tuple2(start, end);
			_v0$5:
			while (true) {
				switch (_v0.a.$) {
					case 0:
						if (!_v0.b.$) {
							var startHex = _v0.a.a;
							var endHex = _v0.b.a;
							var startRgb = $author$project$Anim$Internal$Extra$Color$hexToRgb(startHex);
							var endRgb = $author$project$Anim$Internal$Extra$Color$hexToRgb(endHex);
							var g = $elm$core$Basics$round(startRgb.cV + ((endRgb.cV - startRgb.cV) * t));
							var r = $elm$core$Basics$round(startRgb.dn + ((endRgb.dn - startRgb.dn) * t));
							var b = $elm$core$Basics$round(startRgb.cI + ((endRgb.cI - startRgb.cI) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{cI: b, cV: g, dn: r});
						} else {
							break _v0$5;
						}
					case 1:
						if (_v0.b.$ === 1) {
							var startRgb = _v0.a.a;
							var endRgb = _v0.b.a;
							var r = $elm$core$Basics$round(startRgb.dn + ((endRgb.dn - startRgb.dn) * t));
							var g = $elm$core$Basics$round(startRgb.cV + ((endRgb.cV - startRgb.cV) * t));
							var b = $elm$core$Basics$round(startRgb.cI + ((endRgb.cI - startRgb.cI) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{cI: b, cV: g, dn: r});
						} else {
							break _v0$5;
						}
					case 2:
						if (_v0.b.$ === 2) {
							var startRgba = _v0.a.a;
							var endRgba = _v0.b.a;
							var r = $elm$core$Basics$round(startRgba.dn + ((endRgba.dn - startRgba.dn) * t));
							var g = $elm$core$Basics$round(startRgba.cV + ((endRgba.cV - startRgba.cV) * t));
							var b = $elm$core$Basics$round(startRgba.cI + ((endRgba.cI - startRgba.cI) * t));
							var a = startRgba.cE + ((endRgba.cE - startRgba.cE) * t);
							return $author$project$Anim$Internal$Extra$Color$Rgba(
								{cE: a, cI: b, cV: g, dn: r});
						} else {
							break _v0$5;
						}
					case 3:
						if (_v0.b.$ === 3) {
							var startHsl = _v0.a.a;
							var endHsl = _v0.b.a;
							var s = startHsl.dq + ((endHsl.dq - startHsl.dq) * t);
							var l = startHsl.c2 + ((endHsl.c2 - startHsl.c2) * t);
							var h = startHsl.cW + ((endHsl.cW - startHsl.cW) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsl(
								{cW: h, c2: l, dq: s});
						} else {
							break _v0$5;
						}
					case 4:
						if (_v0.b.$ === 4) {
							var startHsla = _v0.a.a;
							var endHsla = _v0.b.a;
							var s = startHsla.dq + ((endHsla.dq - startHsla.dq) * t);
							var l = startHsla.c2 + ((endHsla.c2 - startHsla.c2) * t);
							var h = startHsla.cW + ((endHsla.cW - startHsla.cW) * t);
							var a = startHsla.cE + ((endHsla.cE - startHsla.cE) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsla(
								{cE: a, cW: h, c2: l, dq: s});
						} else {
							break _v0$5;
						}
					default:
						break _v0$5;
				}
			}
			var startAlpha = function () {
				switch (start.$) {
					case 2:
						var rgba_ = start.a;
						return rgba_.cE;
					case 4:
						var hsla_ = start.a;
						return hsla_.cE;
					case 5:
						var elmColor_ = start.a;
						var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
						return rgba_.bG;
					default:
						return 1.0;
				}
			}();
			var _v1 = _Utils_Tuple2(start, end);
			switch (_v1.b.$) {
				case 3:
					var startHsla = $author$project$Anim$Internal$Extra$Color$toHsla(start);
					var endHsla = $author$project$Anim$Internal$Extra$Color$toHsla(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Hsla(startHsla),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Hsla(
						_Utils_update(
							endHsla,
							{cE: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 4:
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Hsla(
						$author$project$Anim$Internal$Extra$Color$toHsla(start)),
						$temp$end = end;
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 1:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						_Utils_update(
							endRgba,
							{cE: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 0:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						_Utils_update(
							endRgba,
							{cE: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 2:
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(
						$author$project$Anim$Internal$Extra$Color$toRgba(start)),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						$author$project$Anim$Internal$Extra$Color$toRgba(end));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				default:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(endRgba);
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
			}
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress = function (timing) {
	if (timing.A || (timing.K <= 0)) {
		return 1.0;
	} else {
		var animationElapsedMs = A2($elm$core$Basics$max, 0, timing.M - timing.cO);
		return (animationElapsedMs <= 0) ? 0.0 : A2($elm$core$Basics$min, 1.0, animationElapsedMs / timing.K);
	}
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateEasedProgress = F2(
	function (interpolate, anim) {
		var easedProgress = anim.er(
			$author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress(anim));
		return A3(interpolate, easedProgress, anim.bw, anim.m);
	});
var $author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateEasedProgress;
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat = F3(
	function (t, start, end) {
		return start + ((end - start) * t);
	});
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat;
var $author$project$Anim$Internal$Engine$Sub$interpolateFloat = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat;
var $author$project$Anim$Internal$Property$Opacity$toFloat = function (_v0) {
	var o = _v0;
	return o;
};
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateOpacity = F3(
	function (t, start, end) {
		return $author$project$Anim$Internal$Property$Opacity$fromFloat(
			A3(
				$author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat,
				t,
				$author$project$Anim$Internal$Property$Opacity$toFloat(start),
				$author$project$Anim$Internal$Property$Opacity$toFloat(end)));
	});
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateOpacity = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateOpacity;
var $author$project$Anim$Internal$Engine$Sub$interpolateOpacity = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateOpacity;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate = F3(
	function (t, start, end) {
		var _v0 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(start);
		var sx = _v0.a;
		var sy = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(end);
		var ex = _v1.a;
		var ey = _v1.b;
		return {ao: sx + ((ex - sx) * t), ap: sy + ((ey - sy) * t)};
	});
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate;
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolatePerspectiveOrigin;
var $author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolatePerspectiveOrigin;
var $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple = F2(
	function (support, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		var z = _v0.c;
		return support.eB(
			{ao: x, ap: y, aq: z});
	});
var $author$project$Anim$Internal$Property$Rotate$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple = F5(
	function (toTriple, fromTriple, t, start, end) {
		var _v0 = toTriple(start);
		var s1 = _v0.a;
		var s2 = _v0.b;
		var s3 = _v0.c;
		var _v1 = toTriple(end);
		var e1 = _v1.a;
		var e2 = _v1.b;
		var e3 = _v1.c;
		return fromTriple(
			_Utils_Tuple3(
				A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, s1, e1),
				A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, s2, e2),
				A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, s3, e3)));
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$toTriple = F2(
	function (support, coord) {
		var record = support.fV(coord);
		return _Utils_Tuple3(record.ao, record.ap, record.aq);
	});
var $author$project$Anim$Internal$Property$Rotate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateRotate = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Rotate$toTriple, $author$project$Anim$Internal$Property$Rotate$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateRotate = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateRotate;
var $author$project$Anim$Internal$Engine$Sub$interpolateRotate = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateRotate;
var $author$project$Anim$Internal$Property$Scale$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Scale$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateScale = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Scale$toTriple, $author$project$Anim$Internal$Property$Scale$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateScale = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateScale;
var $author$project$Anim$Internal$Engine$Sub$interpolateScale = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateScale;
var $author$project$Anim$Internal$Property$Size$fromTuple = function (_v0) {
	var width = _v0.a;
	var height = _v0.b;
	return {cW: height, P: width};
};
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTuple = F5(
	function (toTuple, fromTuple, t, start, end) {
		var _v0 = toTuple(start);
		var s1 = _v0.a;
		var s2 = _v0.b;
		var _v1 = toTuple(end);
		var e1 = _v1.a;
		var e2 = _v1.b;
		return fromTuple(
			_Utils_Tuple2(
				A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, s1, e1),
				A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, s2, e2)));
	});
var $author$project$Anim$Internal$Property$Size$toTuple = function (_v0) {
	var dimensions = _v0;
	return _Utils_Tuple2(dimensions.P, dimensions.cW);
};
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSize = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Size$toTuple, $author$project$Anim$Internal$Property$Size$fromTuple);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSize = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSize;
var $author$project$Anim$Internal$Engine$Sub$interpolateSize = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSize;
var $author$project$Anim$Internal$Property$Skew$fromTuple = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	return {ao: x, ap: y};
};
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSkew = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Skew$toTuple, $author$project$Anim$Internal$Property$Skew$fromTuple);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSkew = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSkew;
var $author$project$Anim$Internal$Engine$Sub$interpolateSkew = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSkew;
var $author$project$Anim$Internal$Property$Translate$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Property$Translate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTranslate = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Translate$toTriple, $author$project$Anim$Internal$Property$Translate$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTranslate = $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTranslate;
var $author$project$Anim$Internal$Engine$Sub$interpolateTranslate = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTranslate;
var $author$project$Anim$Internal$Engine$Sub$extractPropertyCurrentState = function (anim) {
	var interpolated = F3(
		function (set, interp, a) {
			return set(
				A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, interp, a));
		});
	switch (anim.$) {
		case 0:
			var cssName = anim.a;
			var unit = anim.b;
			var a = anim.c;
			return A3(
				$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty,
				cssName,
				A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateFloat, a),
				unit);
		case 1:
			var cssName = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty,
				cssName,
				A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Extra$Color$interpolate, a));
		case 2:
			var a = anim.a;
			return A3(interpolated, $author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, $author$project$Anim$Internal$Engine$Sub$interpolateOpacity, a);
		case 3:
			var units = anim.a;
			var a = anim.b;
			return A3(
				interpolated,
				function (value) {
					return A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin(value),
						$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits(units));
				},
				$author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin,
				a);
		case 4:
			var a = anim.a;
			return A3(interpolated, $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, $author$project$Anim$Internal$Engine$Sub$interpolateRotate, a);
		case 5:
			var a = anim.a;
			return A3(interpolated, $author$project$Anim$Internal$Builder$PropertyBaselines$setScale, $author$project$Anim$Internal$Engine$Sub$interpolateScale, a);
		case 6:
			var units = anim.a;
			var a = anim.b;
			return A3(
				interpolated,
				function (value) {
					return A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Internal$Builder$PropertyBaselines$setSize(value),
						$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits(units));
				},
				$author$project$Anim$Internal$Engine$Sub$interpolateSize,
				a);
		case 7:
			var a = anim.a;
			return A3(interpolated, $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, $author$project$Anim$Internal$Engine$Sub$interpolateSkew, a);
		default:
			var units = anim.a;
			var a = anim.b;
			return A3(
				interpolated,
				function (value) {
					return A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate(value),
						$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits(units));
				},
				$author$project$Anim$Internal$Engine$Sub$interpolateTranslate,
				a);
	}
};
var $author$project$Anim$Internal$Engine$Sub$Animations$foldl = F3(
	function (f, acc, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$foldl, f, acc, dict);
	});
var $author$project$Anim$Internal$Engine$Sub$extractAnimGroupCurrentStates = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations,
	A2(
		$author$project$Anim$Internal$Engine$Sub$Animations$foldl,
		function (_v0) {
			return $author$project$Anim$Internal$Engine$Sub$extractPropertyCurrentState;
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$empty));
var $author$project$Anim$Internal$Engine$Sub$setSnapshot = function (anims) {
	return A2(
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
		F2(
			function (_v0, anim) {
				return {
					fe: $author$project$Anim$Internal$Engine$Sub$extractAnimGroupCurrentStates(anim)
				};
			}),
		anims);
};
var $author$project$Anim$Internal$Engine$Sub$animate = F2(
	function (_v0, build) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var insertAnimGroup = F3(
			function (animGroupName, animGroup, acc) {
				var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, acc);
				if (_v1.$ === 1) {
					return A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, animGroup, acc);
				} else {
					var existing = _v1.a;
					return A3(
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
						animGroupName,
						A2(
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$addAnimation,
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(existing),
							animGroup),
						acc);
				}
			});
		var builder = build(
			A2(
				$author$project$Anim$Internal$Builder$injectCurrentStates,
				$author$project$Anim$Internal$Engine$Sub$setSnapshot(animGroups),
				state.Z));
		var processed = $author$project$Anim$Internal$Builder$process(builder);
		var generateAnimGroup = F2(
			function (animGroupName, config) {
				var playback = A3($author$project$Anim$Internal$Builder$resolvePlayback, processed.r, processed.w, config.b);
				return A7(
					$author$project$Anim$Internal$Engine$Sub$Generator$generateAnimation,
					playback.r,
					playback.w,
					config.o,
					A2($author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor, animGroupName, builder),
					A2($author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor, animGroupName, builder),
					A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups),
					config.q);
			});
		var nextAnimGroups = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
			insertAnimGroup,
			animGroups,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, generateAnimGroup, processed.co));
		var runAndStartedEvents = A2(
			$elm$core$List$concatMap,
			function (name) {
				return _List_fromArray(
					[
						$author$project$Anim$Internal$Engine$Sub$Run(name),
						$author$project$Anim$Internal$Engine$Sub$Started(name)
					]);
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$names(processed.co));
		var nextState = A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				Z: $author$project$Anim$Internal$Builder$clearAnimData(
					$author$project$Anim$Internal$Builder$mergeBaselines(
						A2($author$project$Anim$Internal$Builder$addAnimationToHistory, processed, builder))),
				X: state.X,
				I: _Utils_ap(state.I, runAndStartedEvents),
				J: true
			},
			nextAnimGroups);
		return nextState;
	});
var $author$project$Anim$Engine$Sub$animate = $author$project$Anim$Internal$Engine$Sub$animate;
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === -1) && (dict.d.$ === -1)) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.e.d.$ === -1) && (!dict.e.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.d.d.$ === -1) && (!dict.d.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === -1) && (!left.a)) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === -1) && (right.a === 1)) {
					if (right.d.$ === -1) {
						if (right.d.a === 1) {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === -1) && (dict.d.$ === -1)) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor === 1) {
			if ((lLeft.$ === -1) && (!lLeft.a)) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === -1) {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === -1) && (left.a === 1)) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === -1) && (!lLeft.a)) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === -1) {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === -1) {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === -1) {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (!_v0.$) {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$update = F3(
	function (name, fn, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$update, name, fn, dict);
	});
var $author$project$Anim$Internal$Builder$for = F2(
	function (elementId, _v0) {
		var data = _v0;
		var anim = data.a;
		var groupDefaults = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
			elementId,
			function (maybeDefaults) {
				return $elm$core$Maybe$Just(
					A2($elm$core$Maybe$withDefault, data.c, maybeDefaults));
			},
			anim.U);
		return _Utils_update(
			data,
			{
				a: _Utils_update(
					anim,
					{
						p: $elm$core$Maybe$Just(elementId),
						U: groupDefaults
					})
			});
	});
var $author$project$Anim$Engine$Sub$for = $author$project$Anim$Internal$Builder$for;
var $author$project$Animation$Sub$PulsingDot$Main$groupName = 'pulsingDot';
var $author$project$Anim$Internal$Builder$getAnimGroups = function (_v0) {
	var data = _v0;
	return data.a.y;
};
var $author$project$Anim$Internal$Builder$getDefaults = function (_v0) {
	var data = _v0;
	return data.c;
};
var $author$project$Anim$Internal$Builder$initDefaults = {_: $author$project$Anim$Internal$Builder$CssUnitStore$empty, h: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, aD: $elm$core$Maybe$Nothing, at: $elm$core$Maybe$Nothing, W: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, aE: $elm$core$Maybe$Nothing, af: $elm$core$Maybe$Nothing, aF: $elm$core$Maybe$Nothing, aH: $elm$core$Maybe$Nothing, aK: $elm$core$Maybe$Nothing, b8: $elm$core$Set$empty, aw: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initPlayback = {w: 0, e: $elm$core$Dict$empty, f: $elm$core$Dict$empty, bn: false, r: $author$project$Anim$Internal$Builder$Once};
var $author$project$Anim$Internal$Builder$initScrollDrivenConfig = {bH: $elm$core$Maybe$Nothing, g: false, b4: $elm$core$Maybe$Nothing, by: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, j: $elm$core$Maybe$Nothing, k: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initState = {ay: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, Q: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, aX: $elm$core$Dict$empty, b1: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init};
var $author$project$Anim$Internal$Builder$init = function () {
	var resetInitEntryScope = function (_v0) {
		var data = _v0;
		var defs = data.c;
		var anim = data.a;
		return _Utils_update(
			data,
			{
				a: _Utils_update(
					anim,
					{p: $elm$core$Maybe$Nothing}),
				c: _Utils_update(
					defs,
					{aH: $elm$core$Maybe$Nothing, aK: $elm$core$Maybe$Nothing, aw: $elm$core$Maybe$Nothing})
			});
	};
	var runInitEntry = F2(
		function (f, builder) {
			return resetInitEntryScope(
				f(builder));
		});
	return A2(
		$elm$core$List$foldl,
		runInitEntry,
		{a: $author$project$Anim$Internal$Builder$initAnimation, c: $author$project$Anim$Internal$Builder$initDefaults, g: false, b: $author$project$Anim$Internal$Builder$initPlayback, n: $author$project$Anim$Internal$Builder$initScrollDrivenConfig, u: $author$project$Anim$Internal$Builder$initState, i: 0});
}();
var $author$project$Anim$Internal$Engine$Shared$PlayState$Complete = 4;
var $author$project$Anim$Internal$Engine$Sub$Generator$init = F5(
	function (defaults, animGroupName, discreteEntryProps, discreteExitProps, properties) {
		var processedProps = A3($author$project$Anim$Internal$Builder$processProperties, defaults, animGroupName, properties);
		var animations = $author$project$Anim$Internal$Engine$Sub$Animations$fromList(
			A2(
				$elm$core$List$filterMap,
				$author$project$Anim$Internal$Engine$Sub$Generator$toAnimation(true),
				processedProps));
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$setWillChange,
			$author$project$Anim$Internal$Builder$willChangeComposite(processedProps),
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit,
				discreteExitProps,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry,
					discreteEntryProps,
					A2(
						$author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations,
						animations,
						A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState, 4, $author$project$Anim$Internal$Engine$Sub$AnimGroup$init)))));
	});
var $author$project$Anim$Internal$Engine$Sub$init = function (propertyInitializers) {
	if (!propertyInitializers.b) {
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				Z: $author$project$Anim$Internal$Builder$init(_List_Nil),
				X: $elm$core$Dict$empty,
				I: _List_Nil,
				J: false
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
	} else {
		var builder = $author$project$Anim$Internal$Builder$init(propertyInitializers);
		var initGroup = F2(
			function (animGroupName, _v1) {
				var properties = _v1.q;
				return A5(
					$author$project$Anim$Internal$Engine$Sub$Generator$init,
					$author$project$Anim$Internal$Builder$getDefaults(builder),
					animGroupName,
					A2($author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor, animGroupName, builder),
					A2($author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor, animGroupName, builder),
					properties);
			});
		var animGroups = $author$project$Anim$Internal$Builder$getAnimGroups(builder);
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				Z: $author$project$Anim$Internal$Builder$clearAnimData(
					$author$project$Anim$Internal$Builder$mergeBaselines(builder)),
				X: $elm$core$Dict$empty,
				I: _List_Nil,
				J: false
			},
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, initGroup, animGroups));
	}
};
var $author$project$Anim$Engine$Sub$init = $author$project$Anim$Internal$Engine$Sub$init;
var $author$project$Anim$Internal$Builder$OpacityConfig = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$clamp = F3(
	function (low, high, number) {
		return (_Utils_cmp(number, low) < 0) ? low : ((_Utils_cmp(number, high) > 0) ? high : number);
	});
var $author$project$Anim$Internal$Builder$getClamp = F4(
	function (animGroupName, propertyKey, axis, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Dict$get,
			_Utils_Tuple3(animGroupName, propertyKey, axis),
			data.u.aX);
	});
var $author$project$Anim$Internal$Builder$getCurrentAnimGroupName = function (_v0) {
	var data = _v0;
	return data.a.p;
};
var $author$project$Anim$Internal$Builder$Opacity$applyClamps = F2(
	function (builder, config) {
		var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(builder);
		if (_v0.$ === 1) {
			return config;
		} else {
			var animGroupName = _v0.a;
			var _v1 = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'opacity', 'value', builder);
			if (_v1.$ === 1) {
				return config;
			} else {
				var _v2 = _v1.a;
				var lo = _v2.a;
				var hi = _v2.b;
				var clampValue = function (v) {
					return $author$project$Anim$Internal$Property$Opacity$fromFloat(
						A3(
							$elm$core$Basics$clamp,
							lo,
							hi,
							$author$project$Anim$Internal$Property$Opacity$toFloat(v)));
				};
				var clampedEnd = clampValue(config.m);
				var clampedStart = A2($elm$core$Maybe$map, clampValue, config.bw);
				var startForDistance = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Opacity$default, clampedStart);
				return _Utils_update(
					config,
					{
						cl: A2($author$project$Anim$Internal$Property$Opacity$distance, startForDistance, clampedEnd),
						m: clampedEnd,
						bw: clampedStart
					});
			}
		}
	});
var $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig = function (_v0) {
	var data = _v0;
	var _v1 = data.a.p;
	if (_v1.$ === 1) {
		return {
			e: $elm$core$Maybe$Just(data.b.e),
			f: $elm$core$Maybe$Just(data.b.f),
			g: $elm$core$Maybe$Nothing,
			d: $elm$core$Maybe$Just(data.a.d),
			b: $elm$core$Maybe$Nothing,
			q: _List_Nil,
			o: data.c.aF,
			i: $elm$core$Maybe$Just(data.i),
			j: data.n.j,
			k: data.n.k
		};
	} else {
		var animGroupName = _v1.a;
		return A2(
			$elm$core$Maybe$withDefault,
			{
				e: $elm$core$Maybe$Just(data.b.e),
				f: $elm$core$Maybe$Just(data.b.f),
				g: $elm$core$Maybe$Nothing,
				d: $elm$core$Maybe$Just(data.a.d),
				b: $elm$core$Maybe$Nothing,
				q: _List_Nil,
				o: data.c.aF,
				i: $elm$core$Maybe$Just(data.i),
				j: data.n.j,
				k: data.n.k
			},
			A2(
				$elm$core$Maybe$map,
				function (config) {
					return _Utils_update(
						config,
						{
							e: function () {
								var _v2 = config.e;
								if (!_v2.$) {
									var groupDiscreteEntry = _v2.a;
									return $elm$core$Maybe$Just(groupDiscreteEntry);
								} else {
									return $elm$core$Maybe$Just(data.b.e);
								}
							}(),
							f: function () {
								var _v3 = config.f;
								if (!_v3.$) {
									var groupDiscreteExit = _v3.a;
									return $elm$core$Maybe$Just(groupDiscreteExit);
								} else {
									return $elm$core$Maybe$Just(data.b.f);
								}
							}(),
							d: function () {
								var _v4 = config.d;
								if (!_v4.$) {
									var groupFrozenAxes = _v4.a;
									return $elm$core$Maybe$Just(groupFrozenAxes);
								} else {
									return $elm$core$Maybe$Just(data.a.d);
								}
							}(),
							o: function () {
								var _v5 = config.o;
								if (!_v5.$) {
									var groupOrder = _v5.a;
									return $elm$core$Maybe$Just(groupOrder);
								} else {
									return data.c.aF;
								}
							}(),
							i: function () {
								var _v6 = config.i;
								if (!_v6.$) {
									var groupThrottleMs = _v6.a;
									return $elm$core$Maybe$Just(groupThrottleMs);
								} else {
									return $elm$core$Maybe$Just(data.i);
								}
							}(),
							j: function () {
								var _v7 = config.j;
								if (!_v7.$) {
									var groupRangeEnd = _v7.a;
									return $elm$core$Maybe$Just(groupRangeEnd);
								} else {
									return data.n.j;
								}
							}(),
							k: function () {
								var _v8 = config.k;
								if (!_v8.$) {
									var groupRangeStart = _v8.a;
									return $elm$core$Maybe$Just(groupRangeStart);
								} else {
									return data.n.k;
								}
							}()
						});
				},
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.y)));
	}
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm$core$Basics$not = _Basics_not;
var $author$project$Anim$Internal$Builder$propertyType = function (prop) {
	switch (prop.$) {
		case 0:
			var cssName = prop.a;
			return 'custom:' + cssName;
		case 1:
			var cssName = prop.a;
			return 'customColor:' + cssName;
		case 2:
			return 'opacity';
		case 3:
			return 'perspectiveOrigin';
		case 4:
			return 'rotate';
		case 5:
			return 'scale';
		case 6:
			return 'size';
		case 7:
			return 'skew';
		default:
			return 'translate';
	}
};
var $author$project$Anim$Internal$Builder$updateCurrentConfig = F2(
	function (config, _v0) {
		var data = _v0;
		var _v1 = data.a.p;
		if (_v1.$ === 1) {
			return data;
		} else {
			var animKey = _v1.a;
			var configWithDiscreteSnapshot = _Utils_update(
				config,
				{
					e: function () {
						var _v16 = config.e;
						if (!_v16.$) {
							return config.e;
						} else {
							return $elm$core$Maybe$Just(data.b.e);
						}
					}(),
					f: function () {
						var _v17 = config.f;
						if (!_v17.$) {
							return config.f;
						} else {
							return $elm$core$Maybe$Just(data.b.f);
						}
					}()
				});
			var newPropertyTypes = A2($elm$core$List$map, $author$project$Anim$Internal$Builder$propertyType, configWithDiscreteSnapshot.q);
			var anim = data.a;
			var mergedConfig = function () {
				var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animKey, anim.y);
				if (!_v2.$) {
					var existing = _v2.a;
					var mergedOrder = function () {
						var _v15 = configWithDiscreteSnapshot.o;
						if (!_v15.$) {
							return configWithDiscreteSnapshot.o;
						} else {
							return existing.o;
						}
					}();
					var filteredExisting = A2(
						$elm$core$List$filter,
						function (p) {
							return !A2(
								$elm$core$List$member,
								$author$project$Anim$Internal$Builder$propertyType(p),
								newPropertyTypes);
						},
						existing.q);
					return _Utils_update(
						existing,
						{
							e: function () {
								var _v3 = configWithDiscreteSnapshot.e;
								if (!_v3.$) {
									var newDiscreteEntry = _v3.a;
									return $elm$core$Maybe$Just(
										A2(
											$elm$core$Dict$union,
											newDiscreteEntry,
											A2($elm$core$Maybe$withDefault, $elm$core$Dict$empty, existing.e)));
								} else {
									return existing.e;
								}
							}(),
							f: function () {
								var _v4 = configWithDiscreteSnapshot.f;
								if (!_v4.$) {
									var newDiscreteExit = _v4.a;
									return $elm$core$Maybe$Just(
										A2(
											$elm$core$Dict$union,
											newDiscreteExit,
											A2($elm$core$Maybe$withDefault, $elm$core$Dict$empty, existing.f)));
								} else {
									return existing.f;
								}
							}(),
							g: function () {
								var _v5 = configWithDiscreteSnapshot.g;
								if (!_v5.$) {
									return configWithDiscreteSnapshot.g;
								} else {
									return existing.g;
								}
							}(),
							d: function () {
								var _v6 = configWithDiscreteSnapshot.d;
								if (!_v6.$) {
									return configWithDiscreteSnapshot.d;
								} else {
									return existing.d;
								}
							}(),
							b: function () {
								var _v7 = _Utils_Tuple2(existing.b, configWithDiscreteSnapshot.b);
								if (!_v7.b.$) {
									if (!_v7.a.$) {
										var existingPlayback = _v7.a.a;
										var incomingPlayback = _v7.b.a;
										return $elm$core$Maybe$Just(
											{
												w: function () {
													var _v8 = incomingPlayback.w;
													if (!_v8.$) {
														return incomingPlayback.w;
													} else {
														return existingPlayback.w;
													}
												}(),
												r: function () {
													var _v9 = incomingPlayback.r;
													if (!_v9.$) {
														return incomingPlayback.r;
													} else {
														return existingPlayback.r;
													}
												}()
											});
									} else {
										var _v10 = _v7.a;
										var incomingPlayback = _v7.b.a;
										return $elm$core$Maybe$Just(incomingPlayback);
									}
								} else {
									var _v11 = _v7.b;
									return existing.b;
								}
							}(),
							q: _Utils_ap(filteredExisting, configWithDiscreteSnapshot.q),
							o: mergedOrder,
							i: function () {
								var _v12 = configWithDiscreteSnapshot.i;
								if (!_v12.$) {
									return configWithDiscreteSnapshot.i;
								} else {
									return existing.i;
								}
							}(),
							j: function () {
								var _v13 = configWithDiscreteSnapshot.j;
								if (!_v13.$) {
									return configWithDiscreteSnapshot.j;
								} else {
									return existing.j;
								}
							}(),
							k: function () {
								var _v14 = configWithDiscreteSnapshot.k;
								if (!_v14.$) {
									return configWithDiscreteSnapshot.k;
								} else {
									return existing.k;
								}
							}()
						});
				} else {
					return configWithDiscreteSnapshot;
				}
			}();
			return _Utils_update(
				data,
				{
					a: _Utils_update(
						anim,
						{
							y: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animKey, mergedConfig, anim.y),
							U: A3(
								$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
								animKey,
								function (maybeDefaults) {
									return $elm$core$Maybe$Just(
										A2($elm$core$Maybe$withDefault, data.c, maybeDefaults));
								},
								anim.U)
						})
				});
		}
	});
var $author$project$Anim$Internal$Builder$Property$add = F2(
	function (propertyConfig, builder) {
		var config = $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig(builder);
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			_Utils_update(
				config,
				{
					q: _Utils_ap(
						config.q,
						_List_fromArray(
							[propertyConfig]))
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Property$configsMatch = F2(
	function (prop1, prop2) {
		var _v0 = _Utils_Tuple2(prop1, prop2);
		_v0$9:
		while (true) {
			switch (_v0.a.$) {
				case 0:
					if (!_v0.b.$) {
						var _v1 = _v0.a;
						var name1 = _v1.a;
						var _v2 = _v0.b;
						var name2 = _v2.a;
						return _Utils_eq(name1, name2);
					} else {
						break _v0$9;
					}
				case 1:
					if (_v0.b.$ === 1) {
						var _v3 = _v0.a;
						var name1 = _v3.a;
						var _v4 = _v0.b;
						var name2 = _v4.a;
						return _Utils_eq(name1, name2);
					} else {
						break _v0$9;
					}
				case 2:
					if (_v0.b.$ === 2) {
						return true;
					} else {
						break _v0$9;
					}
				case 3:
					if (_v0.b.$ === 3) {
						return true;
					} else {
						break _v0$9;
					}
				case 4:
					if (_v0.b.$ === 4) {
						return true;
					} else {
						break _v0$9;
					}
				case 5:
					if (_v0.b.$ === 5) {
						return true;
					} else {
						break _v0$9;
					}
				case 6:
					if (_v0.b.$ === 6) {
						return true;
					} else {
						break _v0$9;
					}
				case 7:
					if (_v0.b.$ === 7) {
						return true;
					} else {
						break _v0$9;
					}
				default:
					if (_v0.b.$ === 8) {
						return true;
					} else {
						break _v0$9;
					}
			}
		}
		return false;
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Anim$Internal$Builder$Property$find = function (predicate) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig,
		A2(
			$elm$core$Basics$composeR,
			function ($) {
				return $.q;
			},
			A2(
				$elm$core$Basics$composeR,
				$elm$core$List$filter(predicate),
				$elm$core$List$head)));
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $author$project$Anim$Internal$Builder$Property$replace = F2(
	function (propertyConfig, builder) {
		var config = $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig(builder);
		var properties = _Utils_ap(
			A2(
				$elm$core$List$filter,
				A2(
					$elm$core$Basics$composeL,
					$elm$core$Basics$not,
					$author$project$Anim$Internal$Builder$Property$configsMatch(propertyConfig)),
				config.q),
			_List_fromArray(
				[propertyConfig]));
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			_Utils_update(
				config,
				{q: properties}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Property$upsert = F2(
	function (propertyConfig, builder) {
		var _v0 = A2(
			$author$project$Anim$Internal$Builder$Property$find,
			$author$project$Anim$Internal$Builder$Property$configsMatch(propertyConfig),
			builder);
		if (!_v0.$) {
			return A2($author$project$Anim$Internal$Builder$Property$replace, propertyConfig, builder);
		} else {
			return A2($author$project$Anim$Internal$Builder$Property$add, propertyConfig, builder);
		}
	});
var $author$project$Anim$Internal$Builder$Opacity$build = function (_v0) {
	var config = _v0.a;
	var builder = _v0.b;
	return A2(
		$author$project$Anim$Internal$Builder$Property$upsert,
		$author$project$Anim$Internal$Builder$OpacityConfig(
			A2($author$project$Anim$Internal$Builder$Opacity$applyClamps, builder, config)),
		builder);
};
var $author$project$Anim$Internal$Builder$Opacity$OpacityBuilder = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$Animate = {$: 0};
var $author$project$Anim$Internal$Builder$Property$defaultConfig = function (defaultEnd) {
	return {z: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, s: $elm$core$Maybe$Nothing, cl: 0, bQ: $elm$core$Maybe$Nothing, m: defaultEnd, O: $author$project$Anim$Internal$Builder$Animate, bv: $elm$core$Maybe$Nothing, bw: $elm$core$Maybe$Nothing, b6: $elm$core$Maybe$Nothing};
};
var $author$project$Anim$Internal$Builder$Opacity$defaultConfig = $author$project$Anim$Internal$Builder$Property$defaultConfig($author$project$Anim$Internal$Property$Opacity$default);
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Anim$Internal$Builder$getScopedDefaults = function (_v0) {
	var data = _v0;
	var _v1 = data.a.p;
	if (_v1.$ === 1) {
		return data.c;
	} else {
		var animGroupName = _v1.a;
		return A2(
			$elm$core$Maybe$withDefault,
			data.c,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.U));
	}
};
var $author$project$Anim$Internal$Builder$getDelay = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).aD;
};
var $author$project$Anim$Internal$Builder$getEasing = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).at;
};
var $author$project$Anim$Internal$Builder$getSpring = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).aE;
};
var $author$project$Anim$Internal$Builder$getTimeSpec = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).af;
};
var $author$project$Anim$Internal$Builder$Property$applyGlobalDefaults = F2(
	function (builder, config) {
		return _Utils_update(
			config,
			{
				s: function () {
					var _v0 = config.s;
					if (!_v0.$) {
						var delay_ = _v0.a;
						return $elm$core$Maybe$Just(delay_);
					} else {
						return $author$project$Anim$Internal$Builder$getDelay(builder);
					}
				}(),
				bQ: function () {
					var _v1 = config.bQ;
					if (!_v1.$) {
						var easing_ = _v1.a;
						return $elm$core$Maybe$Just(easing_);
					} else {
						return $author$project$Anim$Internal$Builder$getEasing(builder);
					}
				}(),
				bv: function () {
					var _v2 = config.bv;
					if (!_v2.$) {
						var spring_ = _v2.a;
						return $elm$core$Maybe$Just(spring_);
					} else {
						return $author$project$Anim$Internal$Builder$getSpring(builder);
					}
				}(),
				b6: function () {
					var _v3 = config.b6;
					if (!_v3.$) {
						var timing_ = _v3.a;
						return $elm$core$Maybe$Just(timing_);
					} else {
						return $author$project$Anim$Internal$Builder$getTimeSpec(builder);
					}
				}()
			});
	});
var $author$project$Anim$Internal$Builder$getBaseline = F2(
	function (key, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.u.Q);
	});
var $author$project$Anim$Internal$Builder$getRuntimeBaseline = F2(
	function (key, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.u.b1);
	});
var $author$project$Anim$Internal$Builder$Property$for = F6(
	function (animGroupName, _v0, extractBaseline, extractExisting, defaultConfig_, builder) {
		var runtimeValue = A2(
			$elm$core$Maybe$andThen,
			extractBaseline,
			A2($author$project$Anim$Internal$Builder$getRuntimeBaseline, animGroupName, builder));
		var existingConfig = A2(
			$elm$core$Maybe$andThen,
			A2(
				$elm$core$Basics$composeR,
				function ($) {
					return $.q;
				},
				A2(
					$elm$core$Basics$composeR,
					$elm$core$List$filterMap(extractExisting),
					$elm$core$List$head)),
			A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder));
		var baselineValue = A2(
			$elm$core$Maybe$andThen,
			extractBaseline,
			A2($author$project$Anim$Internal$Builder$getBaseline, animGroupName, builder));
		if (!existingConfig.$) {
			var config = existingConfig.a;
			return A2(
				$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
				builder,
				_Utils_update(
					config,
					{
						s: $elm$core$Maybe$Nothing,
						cl: 0,
						bQ: $elm$core$Maybe$Nothing,
						m: config.m,
						bv: $elm$core$Maybe$Nothing,
						bw: $elm$core$List$head(
							A2(
								$elm$core$List$filterMap,
								$elm$core$Basics$identity,
								_List_fromArray(
									[
										runtimeValue,
										baselineValue,
										$elm$core$Maybe$Just(config.m)
									]))),
						b6: $elm$core$Maybe$Nothing
					}));
		} else {
			var _v2 = _Utils_Tuple2(runtimeValue, baselineValue);
			if (!_v2.a.$) {
				if (!_v2.b.$) {
					var runtime = _v2.a.a;
					var baseline = _v2.b.a;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								m: baseline,
								bw: $elm$core$Maybe$Just(runtime)
							}));
				} else {
					var runtime = _v2.a.a;
					var _v3 = _v2.b;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								m: runtime,
								bw: $elm$core$Maybe$Just(runtime)
							}));
				}
			} else {
				if (!_v2.b.$) {
					var _v4 = _v2.a;
					var baseline = _v2.b.a;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								m: baseline,
								bw: $elm$core$Maybe$Just(baseline)
							}));
				} else {
					var _v5 = _v2.a;
					var _v6 = _v2.b;
					return A2($author$project$Anim$Internal$Builder$Property$applyGlobalDefaults, builder, defaultConfig_);
				}
			}
		}
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$getOpacity = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 2) {
				var o = v.a;
				return $elm$core$Maybe$Just(o);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'opacity', dict));
};
var $author$project$Anim$Internal$Builder$Opacity$for = F2(
	function (animGroupName, builder) {
		var extractExisting = function (propertyConfig) {
			if (propertyConfig.$ === 2) {
				var cfg = propertyConfig.a;
				return $elm$core$Maybe$Just(cfg);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		};
		var config = A6($author$project$Anim$Internal$Builder$Property$for, animGroupName, 'opacity', $author$project$Anim$Internal$Builder$PropertyBaselines$getOpacity, extractExisting, $author$project$Anim$Internal$Builder$Opacity$defaultConfig, builder);
		return A2(
			$author$project$Anim$Internal$Builder$Opacity$OpacityBuilder,
			config,
			A2($author$project$Anim$Internal$Builder$for, animGroupName, builder));
	});
var $author$project$Anim$Internal$Builder$Opacity$from = F2(
	function (opacity, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Opacity$OpacityBuilder,
			_Utils_update(
				config,
				{
					bw: $elm$core$Maybe$Just(opacity)
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Opacity$to = F2(
	function (endPos, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var startPos = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Opacity$default, config.bw);
		return A2(
			$author$project$Anim$Internal$Builder$Opacity$OpacityBuilder,
			_Utils_update(
				config,
				{
					cl: A2($author$project$Anim$Internal$Property$Opacity$distance, startPos, endPos),
					m: endPos,
					bw: $elm$core$Maybe$Just(startPos)
				}),
			builder);
	});
var $author$project$Anim$Property$Opacity$init = F3(
	function (animationKey, value, animBuilder) {
		return $author$project$Anim$Internal$Builder$Opacity$build(
			A2(
				$author$project$Anim$Internal$Builder$Opacity$to,
				$author$project$Anim$Internal$Property$Opacity$fromFloat(value),
				A2(
					$author$project$Anim$Internal$Builder$Opacity$from,
					$author$project$Anim$Internal$Property$Opacity$fromFloat(value),
					A2($author$project$Anim$Internal$Builder$Opacity$for, animationKey, animBuilder))));
	});
var $author$project$Anim$Internal$Builder$ScaleConfig = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Builder$Property$clampAxis = F2(
	function (range, v) {
		if (!range.$) {
			var _v1 = range.a;
			var lo = _v1.a;
			var hi = _v1.b;
			return A3($elm$core$Basics$clamp, lo, hi, v);
		} else {
			return v;
		}
	});
var $author$project$Anim$Internal$Property$Scale$getX = function (_v0) {
	var x = _v0.ao;
	return x;
};
var $author$project$Anim$Internal$Property$Scale$getY = function (_v0) {
	var y = _v0.ap;
	return y;
};
var $author$project$Anim$Internal$Property$Scale$getZ = function (_v0) {
	var z = _v0.aq;
	return z;
};
var $author$project$Anim$Internal$Builder$Scale$applyClamps = F2(
	function (builder, config) {
		var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(builder);
		if (_v0.$ === 1) {
			return config;
		} else {
			var animGroupName = _v0.a;
			var cz = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'scale', 'z', builder);
			var cy = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'scale', 'y', builder);
			var cx = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'scale', 'x', builder);
			if (_Utils_eq(cx, $elm$core$Maybe$Nothing) && (_Utils_eq(cy, $elm$core$Maybe$Nothing) && _Utils_eq(cz, $elm$core$Maybe$Nothing))) {
				return config;
			} else {
				var clampValue = function (value) {
					return $author$project$Anim$Internal$Property$Scale$fromTriple(
						_Utils_Tuple3(
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cx,
								$author$project$Anim$Internal$Property$Scale$getX(value)),
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cy,
								$author$project$Anim$Internal$Property$Scale$getY(value)),
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cz,
								$author$project$Anim$Internal$Property$Scale$getZ(value))));
				};
				var clampedEnd = clampValue(config.m);
				var clampedStart = A2($elm$core$Maybe$map, clampValue, config.bw);
				var startForDistance = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Scale$default, clampedStart);
				return _Utils_update(
					config,
					{
						cl: A2($author$project$Anim$Internal$Property$Scale$distance, startForDistance, clampedEnd),
						m: clampedEnd,
						bw: clampedStart
					});
			}
		}
	});
var $author$project$Anim$Internal$Builder$getFrozenAxes = F2(
	function (propName, _v0) {
		var data = _v0;
		var _v1 = data.a.p;
		if (_v1.$ === 1) {
			return A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2($elm$core$Dict$get, propName, data.a.d));
		} else {
			var animGroupName = _v1.a;
			var fromGroup = A2(
				$elm$core$Maybe$andThen,
				$elm$core$Dict$get(propName),
				A2(
					$elm$core$Maybe$andThen,
					function ($) {
						return $.d;
					},
					A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.y)));
			var fromGlobal = A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2($elm$core$Dict$get, propName, data.a.d));
			return A2($elm$core$Maybe$withDefault, fromGlobal, fromGroup);
		}
	});
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Anim$Internal$Builder$Property$applyFrozenAxes = F6(
	function (propertyName, toRec, fromRec, calcDistance, builder, config) {
		var frozenAxes = A2($author$project$Anim$Internal$Builder$getFrozenAxes, propertyName, builder);
		if ($elm$core$List$isEmpty(frozenAxes)) {
			return config;
		} else {
			var _v0 = config.bw;
			if (_v0.$ === 1) {
				return config;
			} else {
				var startVal = _v0.a;
				var startRecord = toRec(startVal);
				var endRecord = toRec(config.m);
				var end = fromRec(
					{
						ao: A2($elm$core$List$member, 'x', frozenAxes) ? startRecord.ao : endRecord.ao,
						ap: A2($elm$core$List$member, 'y', frozenAxes) ? startRecord.ap : endRecord.ap,
						aq: A2($elm$core$List$member, 'z', frozenAxes) ? startRecord.aq : endRecord.aq
					});
				return _Utils_update(
					config,
					{
						cl: A2(calcDistance, startVal, end),
						m: end
					});
			}
		}
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord = function (support) {
	return support.eB;
};
var $author$project$Anim$Internal$Property$Scale$fromRecord = $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Shared$Axis3$toRecord = function (support) {
	return support.fV;
};
var $author$project$Anim$Internal$Property$Scale$toRecord = $author$project$Anim$Internal$Property$Shared$Axis3$toRecord($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Builder$Scale$build = function (_v0) {
	var config = _v0.a;
	var builder = _v0.b;
	var clampedConfig = A2($author$project$Anim$Internal$Builder$Scale$applyClamps, builder, config);
	return A2(
		$author$project$Anim$Internal$Builder$Property$upsert,
		$author$project$Anim$Internal$Builder$ScaleConfig(
			A6($author$project$Anim$Internal$Builder$Property$applyFrozenAxes, 'scale', $author$project$Anim$Internal$Property$Scale$toRecord, $author$project$Anim$Internal$Property$Scale$fromRecord, $author$project$Anim$Internal$Property$Scale$distance, builder, clampedConfig)),
		builder);
};
var $author$project$Anim$Internal$Builder$Scale$ScaleBuilder = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$Scale$defaultConfig = $author$project$Anim$Internal$Builder$Property$defaultConfig($author$project$Anim$Internal$Property$Scale$default);
var $author$project$Anim$Internal$Builder$PropertyBaselines$getScale = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 7) {
				var s = v.a;
				return $elm$core$Maybe$Just(s);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'scale', dict));
};
var $author$project$Anim$Internal$Builder$Scale$for = F2(
	function (animGroupName, builder) {
		var extractExisting = function (propertyConfig) {
			if (propertyConfig.$ === 5) {
				var cfg = propertyConfig.a;
				return $elm$core$Maybe$Just(cfg);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		};
		var config = A6($author$project$Anim$Internal$Builder$Property$for, animGroupName, 'scale', $author$project$Anim$Internal$Builder$PropertyBaselines$getScale, extractExisting, $author$project$Anim$Internal$Builder$Scale$defaultConfig, builder);
		return A2(
			$author$project$Anim$Internal$Builder$Scale$ScaleBuilder,
			config,
			A2($author$project$Anim$Internal$Builder$for, animGroupName, builder));
	});
var $author$project$Anim$Internal$Builder$Scale$from = F2(
	function (scale, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Scale$ScaleBuilder,
			_Utils_update(
				config,
				{
					bw: $elm$core$Maybe$Just(scale)
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Scale$fromXYZ = F3(
	function (x, y, z) {
		return $author$project$Anim$Internal$Builder$Scale$from(
			$author$project$Anim$Internal$Property$Scale$fromTriple(
				_Utils_Tuple3(x, y, z)));
	});
var $author$project$Anim$Property$Scale$from = function (uniformScale) {
	return A3($author$project$Anim$Internal$Builder$Scale$fromXYZ, uniformScale, uniformScale, uniformScale);
};
var $elm$core$Set$fromList = function (list) {
	return A3($elm$core$List$foldl, $elm$core$Set$insert, $elm$core$Set$empty, list);
};
var $author$project$Anim$Internal$Builder$markTouchedAxes = F4(
	function (animGroupName, propName, axes, _v0) {
		var data = _v0;
		var anim = data.a;
		var newTouchedAxes = A3(
			$elm$core$Dict$update,
			_Utils_Tuple2(animGroupName, propName),
			function (maybeSet) {
				if (!maybeSet.$) {
					var existing = maybeSet.a;
					return $elm$core$Maybe$Just(
						A3($elm$core$List$foldl, $elm$core$Set$insert, existing, axes));
				} else {
					return $elm$core$Maybe$Just(
						$elm$core$Set$fromList(axes));
				}
			},
			anim.bB);
		return _Utils_update(
			data,
			{
				a: _Utils_update(
					anim,
					{bB: newTouchedAxes})
			});
	});
var $author$project$Anim$Internal$Builder$withCurrentAnimGroup = F2(
	function (f, builder) {
		var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(builder);
		if (!_v0.$) {
			var animGroupName = _v0.a;
			return A2(f, animGroupName, builder);
		} else {
			return builder;
		}
	});
var $author$project$Anim$Internal$Builder$markAxes = F3(
	function (key, axes, builder) {
		return A2(
			$author$project$Anim$Internal$Builder$withCurrentAnimGroup,
			function (animGroupName) {
				return A3($author$project$Anim$Internal$Builder$markTouchedAxes, animGroupName, key, axes);
			},
			builder);
	});
var $author$project$Anim$Internal$Builder$Scale$markAxes = F2(
	function (axes, builder) {
		return A3($author$project$Anim$Internal$Builder$markAxes, 'scale', axes, builder);
	});
var $author$project$Anim$Internal$Builder$Property$setEnd = F4(
	function (default_, distanceFn, newEnd, config) {
		var startVal = A2($elm$core$Maybe$withDefault, default_, config.bw);
		return _Utils_update(
			config,
			{
				cl: A2(distanceFn, startVal, newEnd),
				m: newEnd,
				bw: $elm$core$Maybe$Just(startVal)
			});
	});
var $author$project$Anim$Internal$Builder$Scale$setEnd = F2(
	function (newEnd, config) {
		return A4($author$project$Anim$Internal$Builder$Property$setEnd, $author$project$Anim$Internal$Property$Scale$default, $author$project$Anim$Internal$Property$Scale$distance, newEnd, config);
	});
var $author$project$Anim$Internal$Builder$Scale$to = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Scale$ScaleBuilder,
			A2($author$project$Anim$Internal$Builder$Scale$setEnd, value, config),
			A2(
				$author$project$Anim$Internal$Builder$Scale$markAxes,
				_List_fromArray(
					['x', 'y', 'z']),
				builder));
	});
var $author$project$Anim$Internal$Builder$Scale$toXYZ = F3(
	function (x, y, z) {
		return $author$project$Anim$Internal$Builder$Scale$to(
			$author$project$Anim$Internal$Property$Scale$fromTriple(
				_Utils_Tuple3(x, y, z)));
	});
var $author$project$Anim$Property$Scale$to = function (targetScale) {
	return A3($author$project$Anim$Internal$Builder$Scale$toXYZ, targetScale, targetScale, targetScale);
};
var $author$project$Anim$Property$Scale$init = F3(
	function (animationKey, value, animBuilder) {
		return $author$project$Anim$Internal$Builder$Scale$build(
			A2(
				$author$project$Anim$Property$Scale$to,
				value,
				A2(
					$author$project$Anim$Property$Scale$from,
					value,
					A2($author$project$Anim$Internal$Builder$Scale$for, animationKey, animBuilder))));
	});
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Anim$Internal$Builder$Alternate = 1;
var $author$project$Anim$Internal$Builder$Times = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Builder$alternate = function (_v0) {
	var data = _v0;
	var _v1 = data.a.p;
	if (_v1.$ === 1) {
		var pb = data.b;
		var bumpedIterations = function () {
			var _v2 = pb.r;
			if (!_v2.$) {
				return $author$project$Anim$Internal$Builder$Times(2);
			} else {
				return pb.r;
			}
		}();
		return _Utils_update(
			data,
			{
				b: _Utils_update(
					pb,
					{w: 1, r: bumpedIterations})
			});
	} else {
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			{
				e: $elm$core$Maybe$Nothing,
				f: $elm$core$Maybe$Nothing,
				g: $elm$core$Maybe$Nothing,
				d: $elm$core$Maybe$Nothing,
				b: $elm$core$Maybe$Just(
					{
						w: $elm$core$Maybe$Just(1),
						r: $elm$core$Maybe$Nothing
					}),
				q: _List_Nil,
				o: $elm$core$Maybe$Nothing,
				i: $elm$core$Maybe$Nothing,
				j: $elm$core$Maybe$Nothing,
				k: $elm$core$Maybe$Nothing
			},
			data);
	}
};
var $author$project$Anim$Engine$Sub$alternate = $author$project$Anim$Internal$Builder$alternate;
var $author$project$Anim$Property$Opacity$begin = function (animBuilder) {
	var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(animBuilder);
	if (!_v0.$) {
		var animGroupName = _v0.a;
		return A2($author$project$Anim$Internal$Builder$Opacity$for, animGroupName, animBuilder);
	} else {
		return A2($author$project$Anim$Internal$Builder$Opacity$for, '', animBuilder);
	}
};
var $author$project$Anim$Property$Scale$begin = function (animBuilder) {
	var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(animBuilder);
	if (!_v0.$) {
		var animGroupName = _v0.a;
		return A2($author$project$Anim$Internal$Builder$Scale$for, animGroupName, animBuilder);
	} else {
		return A2($author$project$Anim$Internal$Builder$Scale$for, '', animBuilder);
	}
};
var $author$project$Anim$Internal$Builder$updateScopedDefaults = F2(
	function (updateDefaults, _v0) {
		var data = _v0;
		var _v1 = data.a.p;
		if (_v1.$ === 1) {
			var defs = data.c;
			return _Utils_update(
				data,
				{
					c: updateDefaults(defs)
				});
		} else {
			var animGroupName = _v1.a;
			var anim = data.a;
			var currentDefaults = A2(
				$elm$core$Maybe$withDefault,
				data.c,
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, anim.U));
			var updatedGroupDefaults = A3(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				animGroupName,
				updateDefaults(currentDefaults),
				anim.U);
			return _Utils_update(
				data,
				{
					a: _Utils_update(
						anim,
						{U: updatedGroupDefaults})
				});
		}
	});
var $author$project$Anim$Internal$Builder$duration = F2(
	function (ms, _v0) {
		var data = _v0;
		return A2(
			$author$project$Anim$Internal$Builder$updateScopedDefaults,
			function (defs) {
				return _Utils_update(
					defs,
					{
						af: $elm$core$Maybe$Just(
							$author$project$Shared$TimeSpec$Duration(ms))
					});
			},
			data);
	});
var $author$project$Anim$Engine$Sub$duration = $author$project$Anim$Internal$Builder$duration;
var $author$project$Anim$Internal$Builder$easing = F2(
	function (easingValue, _v0) {
		var data = _v0;
		return A2(
			$author$project$Anim$Internal$Builder$updateScopedDefaults,
			function (defs) {
				return _Utils_update(
					defs,
					{
						at: $elm$core$Maybe$Just(easingValue),
						aE: $elm$core$Maybe$Nothing
					});
			},
			data);
	});
var $author$project$Anim$Engine$Sub$easing = $author$project$Anim$Internal$Builder$easing;
var $author$project$Anim$Property$Opacity$end = $author$project$Anim$Internal$Builder$Opacity$build;
var $author$project$Anim$Property$Scale$end = $author$project$Anim$Internal$Builder$Scale$build;
var $author$project$Anim$Internal$Builder$Infinite = {$: 2};
var $author$project$Anim$Internal$Builder$loopForever = function (_v0) {
	var data = _v0;
	var _v1 = data.a.p;
	if (_v1.$ === 1) {
		var pb = data.b;
		return _Utils_update(
			data,
			{
				b: _Utils_update(
					pb,
					{r: $author$project$Anim$Internal$Builder$Infinite})
			});
	} else {
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			{
				e: $elm$core$Maybe$Nothing,
				f: $elm$core$Maybe$Nothing,
				g: $elm$core$Maybe$Nothing,
				d: $elm$core$Maybe$Nothing,
				b: $elm$core$Maybe$Just(
					{
						w: $elm$core$Maybe$Nothing,
						r: $elm$core$Maybe$Just($author$project$Anim$Internal$Builder$Infinite)
					}),
				q: _List_Nil,
				o: $elm$core$Maybe$Nothing,
				i: $elm$core$Maybe$Nothing,
				j: $elm$core$Maybe$Nothing,
				k: $elm$core$Maybe$Nothing
			},
			data);
	}
};
var $author$project$Anim$Internal$Engine$Sub$loopForever = $author$project$Anim$Internal$Builder$loopForever;
var $author$project$Anim$Engine$Sub$loopForever = $author$project$Anim$Internal$Engine$Sub$loopForever;
var $author$project$Anim$Property$Opacity$to = A2($elm$core$Basics$composeL, $author$project$Anim$Internal$Builder$Opacity$to, $author$project$Anim$Internal$Property$Opacity$fromFloat);
var $author$project$Animation$Sub$PulsingDot$Main$pulse = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Engine$Sub$loopForever,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Engine$Sub$alternate,
		A2(
			$elm$core$Basics$composeR,
			$author$project$Anim$Engine$Sub$duration(1000),
			A2(
				$elm$core$Basics$composeR,
				$author$project$Anim$Engine$Sub$easing($author$project$Motion$Easing$EaseInOut),
				A2(
					$elm$core$Basics$composeR,
					$author$project$Anim$Property$Scale$begin,
					A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Property$Scale$to(0.4),
						A2(
							$elm$core$Basics$composeR,
							$author$project$Anim$Property$Scale$end,
							A2(
								$elm$core$Basics$composeR,
								$author$project$Anim$Property$Opacity$begin,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Property$Opacity$to(0.3),
									$author$project$Anim$Property$Opacity$end)))))))));
var $author$project$Animation$Sub$PulsingDot$Main$init = function () {
	var animState = $author$project$Anim$Engine$Sub$init(
		_List_fromArray(
			[
				A2($author$project$Anim$Property$Scale$init, $author$project$Animation$Sub$PulsingDot$Main$groupName, 1),
				A2($author$project$Anim$Property$Opacity$init, $author$project$Animation$Sub$PulsingDot$Main$groupName, 1)
			]));
	return _Utils_Tuple2(
		{
			a4: A2(
				$author$project$Anim$Engine$Sub$animate,
				animState,
				A2(
					$elm$core$Basics$composeR,
					$author$project$Anim$Engine$Sub$for($author$project$Animation$Sub$PulsingDot$Main$groupName),
					$author$project$Animation$Sub$PulsingDot$Main$pulse))
		},
		$elm$core$Platform$Cmd$none);
}();
var $author$project$Animation$Sub$PulsingDot$Main$GotSubMsg = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Sub$AnimationFrame = $elm$core$Basics$identity;
var $elm$core$Platform$Sub$map = _Platform_map;
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$core$Platform$Sub$none = $elm$core$Platform$Sub$batch(_List_Nil);
var $elm$browser$Browser$AnimationManager$Delta = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$AnimationManager$State = F3(
	function (subs, request, oldTime) {
		return {cu: oldTime, dp: request, dv: subs};
	});
var $elm$browser$Browser$AnimationManager$init = $elm$core$Task$succeed(
	A3($elm$browser$Browser$AnimationManager$State, _List_Nil, $elm$core$Maybe$Nothing, 0));
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$browser$Browser$AnimationManager$now = _Browser_now(0);
var $elm$browser$Browser$AnimationManager$rAF = _Browser_rAF(0);
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$browser$Browser$AnimationManager$onEffects = F3(
	function (router, subs, _v0) {
		var oldTime = _v0.cu;
		var request = _v0.dp;
		var _v1 = _Utils_Tuple2(request, subs);
		if (_v1.a.$ === 1) {
			if (!_v1.b.b) {
				var _v2 = _v1.a;
				return $elm$browser$Browser$AnimationManager$init;
			} else {
				var _v4 = _v1.a;
				return A2(
					$elm$core$Task$andThen,
					function (pid) {
						return A2(
							$elm$core$Task$andThen,
							function (time) {
								return $elm$core$Task$succeed(
									A3(
										$elm$browser$Browser$AnimationManager$State,
										subs,
										$elm$core$Maybe$Just(pid),
										time));
							},
							$elm$browser$Browser$AnimationManager$now);
					},
					$elm$core$Process$spawn(
						A2(
							$elm$core$Task$andThen,
							$elm$core$Platform$sendToSelf(router),
							$elm$browser$Browser$AnimationManager$rAF)));
			}
		} else {
			if (!_v1.b.b) {
				var pid = _v1.a.a;
				return A2(
					$elm$core$Task$andThen,
					function (_v3) {
						return $elm$browser$Browser$AnimationManager$init;
					},
					$elm$core$Process$kill(pid));
			} else {
				return $elm$core$Task$succeed(
					A3($elm$browser$Browser$AnimationManager$State, subs, request, oldTime));
			}
		}
	});
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$browser$Browser$AnimationManager$onSelfMsg = F3(
	function (router, newTime, _v0) {
		var oldTime = _v0.cu;
		var subs = _v0.dv;
		var send = function (sub) {
			if (!sub.$) {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(
						$elm$time$Time$millisToPosix(newTime)));
			} else {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(newTime - oldTime));
			}
		};
		return A2(
			$elm$core$Task$andThen,
			function (pid) {
				return A2(
					$elm$core$Task$andThen,
					function (_v1) {
						return $elm$core$Task$succeed(
							A3(
								$elm$browser$Browser$AnimationManager$State,
								subs,
								$elm$core$Maybe$Just(pid),
								newTime));
					},
					$elm$core$Task$sequence(
						A2($elm$core$List$map, send, subs)));
			},
			$elm$core$Process$spawn(
				A2(
					$elm$core$Task$andThen,
					$elm$core$Platform$sendToSelf(router),
					$elm$browser$Browser$AnimationManager$rAF)));
	});
var $elm$browser$Browser$AnimationManager$Time = function (a) {
	return {$: 0, a: a};
};
var $elm$browser$Browser$AnimationManager$subMap = F2(
	function (func, sub) {
		if (!sub.$) {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Time(
				A2($elm$core$Basics$composeL, func, tagger));
		} else {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Delta(
				A2($elm$core$Basics$composeL, func, tagger));
		}
	});
_Platform_effectManagers['Browser.AnimationManager'] = _Platform_createManager($elm$browser$Browser$AnimationManager$init, $elm$browser$Browser$AnimationManager$onEffects, $elm$browser$Browser$AnimationManager$onSelfMsg, 0, $elm$browser$Browser$AnimationManager$subMap);
var $elm$browser$Browser$AnimationManager$subscription = _Platform_leaf('Browser.AnimationManager');
var $elm$browser$Browser$AnimationManager$onAnimationFrameDelta = function (tagger) {
	return $elm$browser$Browser$AnimationManager$subscription(
		$elm$browser$Browser$AnimationManager$Delta(tagger));
};
var $elm$browser$Browser$Events$onAnimationFrameDelta = $elm$browser$Browser$AnimationManager$onAnimationFrameDelta;
var $author$project$Anim$Internal$Engine$Sub$subscriptions = F2(
	function (toMsg, _v0) {
		var state = _v0.a;
		return state.J ? A2(
			$elm$core$Platform$Sub$map,
			toMsg,
			$elm$browser$Browser$Events$onAnimationFrameDelta($elm$core$Basics$identity)) : $elm$core$Platform$Sub$none;
	});
var $author$project$Anim$Engine$Sub$subscriptions = $author$project$Anim$Internal$Engine$Sub$subscriptions;
var $author$project$Animation$Sub$PulsingDot$Main$subscriptions = function (model) {
	return A2($author$project$Anim$Engine$Sub$subscriptions, $elm$core$Basics$identity, model.a4);
};
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $author$project$Anim$Engine$Sub$Cancelled = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Paused = F2(
	function (a, b) {
		return {$: 5, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Restarted = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Engine$Sub$Resumed = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Engine$Sub$Run = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Engine$Sub$Started = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Engine$Sub$toControlAnimEvent = function (event) {
	switch (event.$) {
		case 0:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Run(key));
		case 1:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Started(key));
		case 2:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Cancelled, key, progressValue));
		case 3:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Paused, key, progressValue));
		case 4:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Resumed(key));
		default:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Restarted(key));
	}
};
var $author$project$Anim$Engine$Sub$Ended = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Engine$Sub$Iteration = F2(
	function (a, b) {
		return {$: 7, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Progress = F2(
	function (a, b) {
		return {$: 8, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$toTickAnimEvent = function (event) {
	switch (event.$) {
		case 1:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Ended(key));
		case 2:
			var key = event.a;
			var iterationNumber = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Iteration, key, iterationNumber));
		default:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Progress, key, progressValue));
	}
};
var $author$project$Anim$Engine$Sub$toAnimEvent = function (event) {
	if (!event.$) {
		var tickEvent = event.a;
		return $author$project$Anim$Engine$Sub$toTickAnimEvent(tickEvent);
	} else {
		var controlEvent = event.a;
		return $author$project$Anim$Engine$Sub$toControlAnimEvent(controlEvent);
	}
};
var $author$project$Anim$Internal$Engine$Sub$Control = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Tick = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList = A2($elm$core$Basics$composeL, $elm$core$Basics$identity, $elm$core$Dict$fromList);
var $author$project$Anim$Internal$Builder$getCurrentAnimationConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Maybe$map,
			A2(
				$elm$core$Basics$composeR,
				function ($) {
					return $.aC;
				},
				function ($) {
					return $.E;
				}),
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.u.ay));
	});
var $author$project$Anim$Internal$Builder$getEmitProgressFor = F2(
	function (animGroupName, builder) {
		var data = builder;
		var globalEnabled = data.g;
		var fromHistory = A2(
			$elm$core$Maybe$andThen,
			function ($) {
				return $.g;
			},
			A2($author$project$Anim$Internal$Builder$getCurrentAnimationConfig, animGroupName, builder));
		var fromCurrentConfig = A2(
			$elm$core$Maybe$andThen,
			function ($) {
				return $.g;
			},
			A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder));
		return A2(
			$elm$core$Maybe$withDefault,
			A2($elm$core$Maybe$withDefault, globalEnabled, fromCurrentConfig),
			fromHistory);
	});
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$groups = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$values(dict);
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$isRunning = function (state) {
	return state === 1;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isRunning(group.bc);
};
var $author$project$Anim$Internal$Engine$Sub$Ended = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Progress = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$toTiming = function (anim) {
	return {cO: anim.cO, M: anim.M, A: anim.A, K: anim.K};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$foldTiming = F2(
	function (f, anim) {
		switch (anim.$) {
			case 0:
				var a = anim.c;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 1:
				var a = anim.b;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 2:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 3:
				var a = anim.b;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 4:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 5:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 6:
				var a = anim.b;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 7:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			default:
				var a = anim.b;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
		}
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration = function (_v0) {
	var group = _v0;
	return group.ci;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getIterations = function (_v0) {
	var group = _v0;
	return group.r;
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$Paused = 2;
var $author$project$Anim$Internal$Engine$Shared$PlayState$isPaused = function (state) {
	return state === 2;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isPaused = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isPaused(group.bc);
};
var $author$project$Anim$Internal$Engine$Sub$Iteration = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimationDirection = function (_v0) {
	var group = _v0;
	return group.w;
};
var $author$project$Anim$Internal$Engine$Sub$Animations$map = F2(
	function (f, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$map, f, dict);
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$applyTiming = F2(
	function (timing, anim) {
		return _Utils_update(
			anim,
			{cO: timing.cO, M: timing.M, A: timing.A, K: timing.K});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming = F2(
	function (f, anim) {
		var apply = function (a) {
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$applyTiming,
				f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a)),
				a);
		};
		switch (anim.$) {
			case 8:
				var units = anim.a;
				var a = anim.b;
				return A2(
					$author$project$Anim$Internal$Engine$Sub$Animation$Translate,
					units,
					apply(a));
			case 4:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
					apply(a));
			case 7:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Skew(
					apply(a));
			case 5:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Scale(
					apply(a));
			case 2:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
					apply(a));
			case 3:
				var units = anim.a;
				var a = anim.b;
				return A2(
					$author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin,
					units,
					apply(a));
			case 6:
				var units = anim.a;
				var a = anim.b;
				return A2(
					$author$project$Anim$Internal$Engine$Sub$Animation$Size,
					units,
					apply(a));
			case 0:
				var cssName = anim.a;
				var unit = anim.b;
				var a = anim.c;
				return A3(
					$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
					cssName,
					unit,
					apply(a));
			default:
				var cssName = anim.a;
				var a = anim.b;
				return A2(
					$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
					cssName,
					apply(a));
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$reset = $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming(
	function (t) {
		return _Utils_update(
			t,
			{M: 0, A: false});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$reverse = function (anim) {
	var swap = function (a) {
		return _Utils_update(
			a,
			{m: a.bw, bw: a.m});
	};
	switch (anim.$) {
		case 8:
			var units = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$Translate,
				units,
				swap(a));
		case 4:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
				swap(a));
		case 7:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Skew(
				swap(a));
		case 5:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Scale(
				swap(a));
		case 2:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
				swap(a));
		case 3:
			var units = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin,
				units,
				swap(a));
		case 6:
			var units = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$Size,
				units,
				swap(a));
		case 0:
			var cssName = anim.a;
			var unit = anim.b;
			var a = anim.c;
			return A3(
				$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
				cssName,
				unit,
				swap(a));
		default:
			var cssName = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
				cssName,
				swap(a));
	}
};
var $author$project$Anim$Internal$Engine$Sub$iterateAnimGroup = F3(
	function (animGroupName, animGroup, animations) {
		var shouldReverse = function () {
			var _v1 = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimationDirection(animGroup);
			if (_v1 === 1) {
				return true;
			} else {
				return false;
			}
		}();
		var nextIteration = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration(animGroup) + 1;
		var anims = A2(
			$author$project$Anim$Internal$Engine$Sub$Animations$map,
			F2(
				function (_v0, anim) {
					var reversed = shouldReverse ? $author$project$Anim$Internal$Engine$Sub$Animation$reverse(anim) : anim;
					return $author$project$Anim$Internal$Engine$Sub$Animation$reset(reversed);
				}),
			animations);
		return _Utils_Tuple2(
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
				1,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration,
					nextIteration,
					A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, anims, animGroup))),
			_List_fromArray(
				[
					A2($author$project$Anim$Internal$Engine$Sub$Iteration, animGroupName, nextIteration)
				]));
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$list = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$values(dict);
};
var $author$project$Anim$Internal$Engine$Sub$calculateProgress = $author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress;
var $author$project$Anim$Internal$Engine$Sub$overallProgress = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Sub$Animations$list,
		A2(
			$elm$core$Basics$composeR,
			$elm$core$List$map(
				$author$project$Anim$Internal$Engine$Sub$Animation$foldTiming($author$project$Anim$Internal$Engine$Sub$calculateProgress)),
			A2(
				$elm$core$Basics$composeR,
				$elm$core$List$maximum,
				$elm$core$Maybe$withDefault(0)))));
var $author$project$Anim$Internal$Engine$Sub$updateTiming = function (deltaMs) {
	return $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming(
		function (timing) {
			if (timing.A) {
				return timing;
			} else {
				var newElapsedMs = timing.M + deltaMs;
				var animationElapsedMs = A2($elm$core$Basics$max, 0, newElapsedMs - timing.cO);
				return _Utils_update(
					timing,
					{
						M: newElapsedMs,
						A: _Utils_cmp(animationElapsedMs, timing.K) > -1
					});
			}
		});
};
var $author$project$Anim$Internal$Engine$Sub$handleTick = F3(
	function (deltaMs, animGroupName, animGroup) {
		if ($author$project$Anim$Internal$Engine$Sub$AnimGroup$isPaused(animGroup)) {
			return _Utils_Tuple2(animGroup, _List_Nil);
		} else {
			var updatedAnimations = A2(
				$author$project$Anim$Internal$Engine$Sub$Animations$map,
				function (_v1) {
					return $author$project$Anim$Internal$Engine$Sub$updateTiming(deltaMs);
				},
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(animGroup));
			var allPropertiesComplete = A2(
				$elm$core$List$all,
				$author$project$Anim$Internal$Engine$Sub$Animation$foldTiming(
					function ($) {
						return $.A;
					}),
				$author$project$Anim$Internal$Engine$Sub$Animations$list(updatedAnimations));
			if (allPropertiesComplete && $author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning(animGroup)) {
				var shouldIterate = function () {
					var _v0 = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getIterations(animGroup);
					switch (_v0.$) {
						case 2:
							return true;
						case 1:
							var totalIterations = _v0.a;
							return _Utils_cmp(
								$author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration(animGroup),
								totalIterations) < 0;
						default:
							return false;
					}
				}();
				return shouldIterate ? A3($author$project$Anim$Internal$Engine$Sub$iterateAnimGroup, animGroupName, animGroup, updatedAnimations) : _Utils_Tuple2(
					A2(
						$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
						4,
						A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, updatedAnimations, animGroup)),
					_List_fromArray(
						[
							$author$project$Anim$Internal$Engine$Sub$Ended(animGroupName)
						]));
			} else {
				var updatedAnimGroup = A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, updatedAnimations, animGroup);
				return _Utils_Tuple2(
					updatedAnimGroup,
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning(updatedAnimGroup) ? _List_fromArray(
						[
							A2(
							$author$project$Anim$Internal$Engine$Sub$Progress,
							animGroupName,
							$author$project$Anim$Internal$Engine$Sub$overallProgress(updatedAnimGroup))
						]) : _List_Nil);
			}
		}
	});
var $author$project$Anim$Internal$Engine$Sub$tick = F2(
	function (deltaMs, _v0) {
		var animGroupName = _v0.a;
		var animGroup = _v0.b;
		var _v1 = A3($author$project$Anim$Internal$Engine$Sub$handleTick, deltaMs, animGroupName, animGroup);
		var newAnimGroup = _v1.a;
		var events = _v1.b;
		return _Utils_Tuple2(
			_Utils_Tuple2(animGroupName, newAnimGroup),
			events);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$toList(dict);
};
var $elm$core$List$unzip = function (pairs) {
	var step = F2(
		function (_v0, _v1) {
			var x = _v0.a;
			var y = _v0.b;
			var xs = _v1.a;
			var ys = _v1.b;
			return _Utils_Tuple2(
				A2($elm$core$List$cons, x, xs),
				A2($elm$core$List$cons, y, ys));
		});
	return A3(
		$elm$core$List$foldr,
		step,
		_Utils_Tuple2(_List_Nil, _List_Nil),
		pairs);
};
var $author$project$Anim$Internal$Engine$Sub$update = F2(
	function (msg, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var deltaMs = msg;
		var _v2 = $elm$core$List$unzip(
			A2(
				$elm$core$List$map,
				$author$project$Anim$Internal$Engine$Sub$tick(deltaMs),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toList(animGroups)));
		var groups = _v2.a;
		var events = _v2.b;
		var allEvents = $elm$core$List$concat(events);
		var filteredEvents = A2(
			$elm$core$List$filter,
			function (e) {
				if (!e.$) {
					var animGroupName = e.a;
					return A2($author$project$Anim$Internal$Builder$getEmitProgressFor, animGroupName, state.Z);
				} else {
					return true;
				}
			},
			allEvents);
		var updatedGroups = $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList(groups);
		var stillRunning = A2(
			$elm$core$List$any,
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(updatedGroups));
		return _Utils_Tuple2(
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimState,
				{Z: state.Z, X: state.X, I: _List_Nil, J: stillRunning},
				updatedGroups),
			_Utils_ap(
				A2($elm$core$List$map, $author$project$Anim$Internal$Engine$Sub$Control, state.I),
				A2($elm$core$List$map, $author$project$Anim$Internal$Engine$Sub$Tick, filteredEvents)));
	});
var $author$project$Anim$Engine$Sub$update = function (msg) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Sub$update(msg),
		$elm$core$Tuple$mapSecond(
			$elm$core$List$filterMap($author$project$Anim$Engine$Sub$toAnimEvent)));
};
var $author$project$Animation$Sub$PulsingDot$Main$update = F2(
	function (msg, model) {
		var animMsg = msg;
		var _v1 = A2($author$project$Anim$Engine$Sub$update, animMsg, model.a4);
		var animState = _v1.a;
		return _Utils_Tuple2(
			_Utils_update(
				model,
				{a4: animState}),
			$elm$core$Platform$Cmd$none);
	});
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Anim$Internal$Property$Rotate$toCssString = function (_v0) {
	var angles = _v0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(!(!angles.ao)) ? $elm$core$Maybe$Just(
				'rotateX(' + ($elm$core$String$fromFloat(angles.ao) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.ap)) ? $elm$core$Maybe$Just(
				'rotateY(' + ($elm$core$String$fromFloat(angles.ap) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.aq)) ? $elm$core$Maybe$Just(
				'rotateZ(' + ($elm$core$String$fromFloat(angles.aq) + 'deg)')) : $elm$core$Maybe$Nothing
			]));
	return $elm$core$List$isEmpty(parts) ? 'rotateZ(0deg)' : A2($elm$core$String$join, ' ', parts);
};
var $author$project$Anim$Internal$Property$Scale$toCssString = function (_v0) {
	var z = _v0.aq;
	var y = _v0.ap;
	var x = _v0.ao;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(x !== 1.0) ? $elm$core$Maybe$Just(
				'scaleX(' + ($elm$core$String$fromFloat(x) + ')')) : $elm$core$Maybe$Nothing,
				(y !== 1.0) ? $elm$core$Maybe$Just(
				'scaleY(' + ($elm$core$String$fromFloat(y) + ')')) : $elm$core$Maybe$Nothing,
				(z !== 1.0) ? $elm$core$Maybe$Just(
				'scaleZ(' + ($elm$core$String$fromFloat(z) + ')')) : $elm$core$Maybe$Nothing
			]));
	if (!parts.b) {
		return 'scale3d(1,1,1)';
	} else {
		if (!parts.b.b) {
			var single = parts.a;
			return single;
		} else {
			var multiple = parts;
			return A2($elm$core$String$join, ' ', multiple);
		}
	}
};
var $author$project$Anim$Internal$Property$Skew$toCssString = function (_v0) {
	var values = _v0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(!(!values.ao)) ? $elm$core$Maybe$Just(
				'skewX(' + ($elm$core$String$fromFloat(values.ao) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!values.ap)) ? $elm$core$Maybe$Just(
				'skewY(' + ($elm$core$String$fromFloat(values.ap) + 'deg)')) : $elm$core$Maybe$Nothing
			]));
	if (!parts.b) {
		return 'skew(0deg, 0deg)';
	} else {
		if (!parts.b.b) {
			var single = parts.a;
			return single;
		} else {
			var multiple = parts;
			return A2($elm$core$String$join, ' ', multiple);
		}
	}
};
var $author$project$Anim$Internal$Unit$toCssSuffix = function (unit) {
	switch (unit) {
		case 0:
			return 'cap';
		case 1:
			return 'ch';
		case 2:
			return 'cm';
		case 3:
			return 'cqb';
		case 4:
			return 'cqh';
		case 5:
			return 'cqi';
		case 6:
			return 'cqmax';
		case 7:
			return 'cqmin';
		case 8:
			return 'cqw';
		case 9:
			return 'dvb';
		case 10:
			return 'dvh';
		case 11:
			return 'dvi';
		case 12:
			return 'dvmax';
		case 13:
			return 'dvmin';
		case 14:
			return 'dvw';
		case 15:
			return 'em';
		case 16:
			return 'ex';
		case 17:
			return 'ic';
		case 18:
			return 'in';
		case 19:
			return 'lh';
		case 20:
			return 'lvb';
		case 21:
			return 'lvh';
		case 22:
			return 'lvi';
		case 23:
			return 'lvmax';
		case 24:
			return 'lvmin';
		case 25:
			return 'lvw';
		case 26:
			return 'mm';
		case 27:
			return 'pc';
		case 28:
			return '%';
		case 29:
			return 'pt';
		case 30:
			return 'px';
		case 31:
			return 'Q';
		case 32:
			return 'rcap';
		case 33:
			return 'rch';
		case 34:
			return 'rem';
		case 35:
			return 'rex';
		case 36:
			return 'ric';
		case 37:
			return 'rlh';
		case 38:
			return 'svb';
		case 39:
			return 'svh';
		case 40:
			return 'svi';
		case 41:
			return 'svmax';
		case 42:
			return 'svmin';
		case 43:
			return 'svw';
		case 44:
			return 'vb';
		case 45:
			return 'vh';
		case 46:
			return 'vi';
		case 47:
			return 'vmax';
		case 48:
			return 'vmin';
		case 49:
			return 'vw';
		default:
			return '';
	}
};
var $author$project$Anim$Internal$Property$Translate$toCssString = F2(
	function (axes, _v0) {
		var coords = _v0;
		return 'translate3d(' + ($elm$core$String$fromFloat(coords.ao) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.ao) + (', ' + ($elm$core$String$fromFloat(coords.ap) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.ap) + (', ' + ($elm$core$String$fromFloat(coords.aq) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.aq) + ')'))))))));
	});
var $author$project$Anim$Internal$Engine$Sub$collectCurrentTransform = F2(
	function (anim, acc) {
		switch (anim.$) {
			case 8:
				var units = anim.a;
				var a = anim.b;
				return _Utils_update(
					acc,
					{
						b9: A2(
							$author$project$Anim$Internal$Property$Translate$toCssString,
							units,
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateTranslate, a))
					});
			case 4:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						b$: $author$project$Anim$Internal$Property$Rotate$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateRotate, a))
					});
			case 7:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						b3: $author$project$Anim$Internal$Property$Skew$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSkew, a))
					});
			case 5:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						b2: $author$project$Anim$Internal$Property$Scale$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateScale, a))
					});
			default:
				return acc;
		}
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteEntry = function (_v0) {
	var group = _v0;
	return group.cj;
};
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $author$project$Anim$Internal$Engine$Sub$discreteEntryStyles = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteEntry,
	A2(
		$elm$core$Basics$composeR,
		$elm$core$Dict$toList,
		$elm$core$List$map(
			function (_v0) {
				var prop = _v0.a;
				var value = _v0.b;
				return A2($elm$html$Html$Attributes$style, prop, value);
			})));
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteExit = function (_v0) {
	var group = _v0;
	return group.ck;
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$isComplete = function (state) {
	return state === 4;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isComplete = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isComplete(group.bc);
};
var $author$project$Anim$Internal$Engine$Sub$discreteExitStyles = function (animGroup) {
	return A2(
		$elm$core$List$map,
		function (_v0) {
			var prop = _v0.a;
			var to = _v0.b.b7;
			var from = _v0.b.bR;
			return $author$project$Anim$Internal$Engine$Sub$AnimGroup$isComplete(animGroup) ? A2($elm$html$Html$Attributes$style, prop, to) : A2($elm$html$Html$Attributes$style, prop, from);
		},
		$elm$core$Dict$toList(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteExit(animGroup)));
};
var $author$project$Anim$Internal$Builder$emptyTransformParts = {b$: '', b2: '', b3: '', b9: ''};
var $elm$core$String$concat = function (strings) {
	return A2($elm$core$String$join, '', strings);
};
var $avh4$elm_color$Color$toCssString = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	var roundTo = function (x) {
		return $elm$core$Basics$round(x * 1000) / 1000;
	};
	var pct = function (x) {
		return $elm$core$Basics$round(x * 10000) / 100;
	};
	return $elm$core$String$concat(
		_List_fromArray(
			[
				'rgba(',
				$elm$core$String$fromFloat(
				pct(r)),
				'%,',
				$elm$core$String$fromFloat(
				pct(g)),
				'%,',
				$elm$core$String$fromFloat(
				pct(b)),
				'%,',
				$elm$core$String$fromFloat(
				roundTo(a)),
				')'
			]));
};
var $author$project$Anim$Internal$Extra$Color$toCssString = function (color) {
	var stringify = F2(
		function (constructor, components) {
			return constructor + ('(' + (A2($elm$core$String$join, ', ', components) + ')'));
		});
	switch (color.$) {
		case 0:
			var hex = color.a;
			return hex;
		case 1:
			var b = color.a.cI;
			var g = color.a.cV;
			var r = color.a.dn;
			return A2(
				stringify,
				'rgb',
				_List_fromArray(
					[
						$elm$core$String$fromInt(r),
						$elm$core$String$fromInt(g),
						$elm$core$String$fromInt(b)
					]));
		case 2:
			var a = color.a.cE;
			var b = color.a.cI;
			var g = color.a.cV;
			var r = color.a.dn;
			return A2(
				stringify,
				'rgba',
				_List_fromArray(
					[
						$elm$core$String$fromInt(r),
						$elm$core$String$fromInt(g),
						$elm$core$String$fromInt(b),
						$elm$core$String$fromFloat(a)
					]));
		case 3:
			var l = color.a.c2;
			var s = color.a.dq;
			var h = color.a.cW;
			return A2(
				stringify,
				'hsl',
				_List_fromArray(
					[
						$elm$core$String$fromFloat(h),
						$elm$core$String$fromFloat(s) + '%',
						$elm$core$String$fromFloat(l) + '%'
					]));
		case 4:
			var a = color.a.cE;
			var l = color.a.c2;
			var s = color.a.dq;
			var h = color.a.cW;
			return A2(
				stringify,
				'hsla',
				_List_fromArray(
					[
						$elm$core$String$fromFloat(h),
						$elm$core$String$fromFloat(s) + '%',
						$elm$core$String$fromFloat(l) + '%',
						$elm$core$String$fromFloat(a)
					]));
		default:
			var elmColor_ = color.a;
			return $avh4$elm_color$Color$toCssString(elmColor_);
	}
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString = F2(
	function (axes, _v0) {
		var y = _v0.ap;
		var x = _v0.ao;
		return $elm$core$String$fromFloat(x) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.ao) + (' ' + ($elm$core$String$fromFloat(y) + $author$project$Anim$Internal$Unit$toCssSuffix(axes.ap))));
	});
var $author$project$Anim$Internal$Engine$Sub$getNonTransformStyleAttribute = function (anim) {
	switch (anim.$) {
		case 0:
			var cssName = anim.a;
			var unit = anim.b;
			var a = anim.c;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					cssName,
					_Utils_ap(
						$elm$core$String$fromFloat(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateFloat, a)),
						unit))
				]);
		case 1:
			var cssName = anim.a;
			var a = anim.b;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					cssName,
					$author$project$Anim$Internal$Extra$Color$toCssString(
						A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Extra$Color$interpolate, a)))
				]);
		case 2:
			var a = anim.a;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'opacity',
					$elm$core$String$fromFloat(
						$author$project$Anim$Internal$Property$Opacity$toFloat(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateOpacity, a))))
				]);
		case 3:
			var units = anim.a;
			var a = anim.b;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'perspective-origin',
					A2(
						$author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString,
						units,
						A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin, a)))
				]);
		case 4:
			return _List_Nil;
		case 5:
			return _List_Nil;
		case 6:
			var units = anim.a;
			var a = anim.b;
			var size = A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSize, a);
			var _v1 = $author$project$Anim$Internal$Property$Size$toTuple(size);
			var width = _v1.a;
			var height = _v1.b;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					_Utils_ap(
						$elm$core$String$fromFloat(width),
						$author$project$Anim$Internal$Unit$toCssSuffix(units.ao))),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					_Utils_ap(
						$elm$core$String$fromFloat(height),
						$author$project$Anim$Internal$Unit$toCssSuffix(units.ap)))
				]);
		case 7:
			return _List_Nil;
		default:
			return _List_Nil;
	}
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getWillChange = function (_v0) {
	var group = _v0;
	return group.cC;
};
var $author$project$Anim$Internal$Engine$Sub$transformOrderToPart = F2(
	function (parts, property) {
		switch (property) {
			case 0:
				return parts.b9;
			case 1:
				return parts.b$;
			case 2:
				return parts.b3;
			default:
				return parts.b2;
		}
	});
var $author$project$Anim$Internal$Engine$Sub$attributes = F2(
	function (animGroupName, _v0) {
		var animGroups = _v0.b;
		var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups);
		if (_v1.$ === 1) {
			return _List_Nil;
		} else {
			var animGroup = _v1.a;
			var willChangeStyle = function () {
				if ($author$project$Anim$Internal$Engine$Sub$AnimGroup$isComplete(animGroup)) {
					return _List_Nil;
				} else {
					var _v2 = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getWillChange(animGroup);
					if (_v2 === '') {
						return _List_Nil;
					} else {
						var value = _v2;
						return _List_fromArray(
							[
								A2($elm$html$Html$Attributes$style, 'will-change', value)
							]);
					}
				}
			}();
			var discreteStyles = _Utils_ap(
				$author$project$Anim$Internal$Engine$Sub$discreteEntryStyles(animGroup),
				$author$project$Anim$Internal$Engine$Sub$discreteExitStyles(animGroup));
			var currentOrder = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder(animGroup);
			var anims = $author$project$Anim$Internal$Engine$Sub$Animations$list(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(animGroup));
			var nonTransformStyles = A2($elm$core$List$concatMap, $author$project$Anim$Internal$Engine$Sub$getNonTransformStyleAttribute, anims);
			var transformParts = A3($elm$core$List$foldl, $author$project$Anim$Internal$Engine$Sub$collectCurrentTransform, $author$project$Anim$Internal$Builder$emptyTransformParts, anims);
			var transformString = A2(
				$elm$core$String$join,
				' ',
				A2(
					$elm$core$List$filter,
					A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$String$isEmpty),
					A2(
						$elm$core$List$map,
						$author$project$Anim$Internal$Engine$Sub$transformOrderToPart(transformParts),
						currentOrder)));
			var transformStyle = $elm$core$String$isEmpty(transformString) ? _List_Nil : _List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'transform', transformString)
				]);
			return _Utils_ap(
				willChangeStyle,
				_Utils_ap(
					transformStyle,
					_Utils_ap(nonTransformStyles, discreteStyles)));
		}
	});
var $author$project$Anim$Engine$Sub$attributes = $author$project$Anim$Internal$Engine$Sub$attributes;
var $elm$json$Json$Encode$string = _Json_wrap;
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $author$project$Animation$Sub$PulsingDot$Main$view = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('example-stage')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_Utils_ap(
					A2($author$project$Anim$Engine$Sub$attributes, $author$project$Animation$Sub$PulsingDot$Main$groupName, model.a4),
					_List_fromArray(
						[
							A2($elm$html$Html$Attributes$style, 'width', '80px'),
							A2($elm$html$Html$Attributes$style, 'height', '80px'),
							A2($elm$html$Html$Attributes$style, 'border-radius', '50%'),
							A2($elm$html$Html$Attributes$style, 'background-color', '#e53935')
						])),
				_List_Nil)
			]));
};
var $author$project$Animation$Sub$PulsingDot$Main$main = $elm$browser$Browser$element(
	{
		eM: function (_v0) {
			return $author$project$Animation$Sub$PulsingDot$Main$init;
		},
		fB: $author$project$Animation$Sub$PulsingDot$Main$subscriptions,
		f$: $author$project$Animation$Sub$PulsingDot$Main$update,
		f0: $author$project$Animation$Sub$PulsingDot$Main$view
	});
_Platform_export({'Animation':{'Sub':{'PulsingDot':{'Main':{'init':$author$project$Animation$Sub$PulsingDot$Main$main(
	$elm$json$Json$Decode$succeed(0))(0)}}}}});}(this));