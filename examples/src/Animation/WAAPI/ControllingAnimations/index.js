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
	if (region.bz.bv === region.n.bv)
	{
		return 'on line ' + region.bz.bv;
	}
	return 'on lines ' + region.bz.bv + ' through ' + region.n.bv;
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
		impl.eY,
		impl.gb,
		impl.fN,
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
		aK: func(record.aK),
		cI: record.cI,
		cD: record.cD
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
		var message = !tag ? value : tag < 3 ? value.a : value.aK;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.cI;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.cD) && event.preventDefault(),
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
		impl.eY,
		impl.gb,
		impl.fN,
		function(sendToApp, initialModel) {
			var view = impl.gc;
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
		impl.eY,
		impl.gb,
		impl.fN,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.cH && impl.cH(sendToApp)
			var view = impl.gc;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.d9);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.f4) && (_VirtualDom_doc.title = title = doc.f4);
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
	var onUrlChange = impl.fg;
	var onUrlRequest = impl.fh;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		cH: function(sendToApp)
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
							&& curr.dw === next.dw
							&& curr.c6 === next.c6
							&& curr.ds.a === next.ds.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		eY: function(flags)
		{
			return A3(impl.eY, flags, _Browser_getUrl(), key);
		},
		gc: impl.gc,
		gb: impl.gb,
		fN: impl.fN
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
		? { eR: 'hidden', ek: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { eR: 'mozHidden', ek: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { eR: 'msHidden', ek: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { eR: 'webkitHidden', ek: 'webkitvisibilitychange' }
		: { eR: 'hidden', ek: 'visibilitychange' };
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
		dD: _Browser_getScene(),
		dM: {
			ar: _Browser_window.pageXOffset,
			as: _Browser_window.pageYOffset,
			dN: _Browser_doc.documentElement.clientWidth,
			c3: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		dN: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		c3: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
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
			dD: {
				dN: node.scrollWidth,
				c3: node.scrollHeight
			},
			dM: {
				ar: node.scrollLeft,
				as: node.scrollTop,
				dN: node.clientWidth,
				c3: node.clientHeight
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
			dD: _Browser_getScene(),
			dM: {
				ar: x,
				as: y,
				dN: _Browser_doc.documentElement.clientWidth,
				c3: _Browser_doc.documentElement.clientHeight
			},
			eE: {
				ar: x + rect.left,
				as: y + rect.top,
				dN: rect.width,
				c3: rect.height
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
		if (!builder.B) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.G),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.G);
		} else {
			var treeLen = builder.B * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.H) : builder.H;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.B);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.G) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.G);
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
					{H: nodeList, B: (len / $elm$core$Array$branchFactor) | 0, G: tail});
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
		return {c$: fragment, c6: host, dq: path, ds: port_, dw: protocol, dx: query};
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
var $author$project$Anim$Unit$Cqh = 4;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup = 'bouncingBall';
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimState = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$AnimBuilder = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Builder$Normal = 0;
var $author$project$Anim$Internal$Builder$Once = {$: 0};
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $author$project$Anim$Internal$Builder$CssUnitStore$empty = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$AnimGroups = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$init = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Builder$initAnimation = {C: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, aX: $author$project$Anim$Internal$Builder$CssUnitStore$empty, r: $elm$core$Maybe$Nothing, e: $elm$core$Dict$empty, W: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, bE: $elm$core$Dict$empty};
var $author$project$Anim$Internal$Builder$clearAnimData = function (_v0) {
	var data = _v0;
	var pb = data.b;
	return _Utils_update(
		data,
		{
			a: $author$project$Anim$Internal$Builder$initAnimation,
			b: _Utils_update(
				pb,
				{A: 0, f: $elm$core$Dict$empty, g: $elm$core$Dict$empty, t: $author$project$Anim$Internal$Builder$Once})
		});
};
var $author$project$Anim$Internal$Builder$getAnimGroups = function (_v0) {
	var data = _v0;
	return data.a.C;
};
var $author$project$Anim$Internal$Builder$getDefaults = function (_v0) {
	var data = _v0;
	return data.c;
};
var $elm$core$Basics$compare = _Utils_compare;
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
var $author$project$Anim$Internal$Builder$getAnimGroupConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.C);
	});
var $author$project$Anim$Internal$Builder$getDiscreteEntryProperties = function (_v0) {
	var data = _v0;
	return data.b.f;
};
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
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor = F2(
	function (animGroupName, builder) {
		var _v0 = A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder);
		if (!_v0.$) {
			var config = _v0.a;
			return A2(
				$elm$core$Maybe$withDefault,
				$author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder),
				A2($elm$core$Maybe$map, $elm$core$Basics$identity, config.f));
		} else {
			return $author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder);
		}
	});
var $author$project$Anim$Internal$Builder$getDiscreteExitProperties = function (_v0) {
	var data = _v0;
	return data.b.g;
};
var $author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor = F2(
	function (animGroupName, builder) {
		var _v0 = A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder);
		if (!_v0.$) {
			var config = _v0.a;
			return A2(
				$elm$core$Maybe$withDefault,
				$author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder),
				A2($elm$core$Maybe$map, $elm$core$Basics$identity, config.g));
		} else {
			return $author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder);
		}
	});
var $elm$core$Set$Set_elm_builtin = $elm$core$Basics$identity;
var $elm$core$Set$empty = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Unit$emptyCssUnitAxes = {ar: $elm$core$Maybe$Nothing, as: $elm$core$Maybe$Nothing, at: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initDefaults = {ab: $author$project$Anim$Internal$Builder$CssUnitStore$empty, i: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, aH: $elm$core$Maybe$Nothing, ax: $elm$core$Maybe$Nothing, Z: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, aI: $elm$core$Maybe$Nothing, ah: $elm$core$Maybe$Nothing, aJ: $elm$core$Maybe$Nothing, aQ: $elm$core$Maybe$Nothing, aT: $elm$core$Maybe$Nothing, ch: $elm$core$Set$empty, aA: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initPlayback = {A: 0, f: $elm$core$Dict$empty, g: $elm$core$Dict$empty, bt: false, t: $author$project$Anim$Internal$Builder$Once};
var $author$project$Anim$Internal$Builder$initScrollDrivenConfig = {bM: $elm$core$Maybe$Nothing, h: false, cc: $elm$core$Maybe$Nothing, bB: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, k: $elm$core$Maybe$Nothing, l: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initState = {aC: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, S: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, a4: $elm$core$Dict$empty, b9: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init};
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
					{r: $elm$core$Maybe$Nothing}),
				c: _Utils_update(
					defs,
					{aQ: $elm$core$Maybe$Nothing, aT: $elm$core$Maybe$Nothing, aA: $elm$core$Maybe$Nothing})
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
		{a: $author$project$Anim$Internal$Builder$initAnimation, c: $author$project$Anim$Internal$Builder$initDefaults, h: false, b: $author$project$Anim$Internal$Builder$initPlayback, o: $author$project$Anim$Internal$Builder$initScrollDrivenConfig, x: $author$project$Anim$Internal$Builder$initState, j: 0});
}();
var $author$project$Anim$Internal$Builder$PropertyBaselines$PropertyBaselines = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Builder$PropertyBaselines$empty = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Builder$PropertyBaselines$CustomColorPropertyValue = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
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
var $author$project$Anim$Internal$Engine$WAAPI$Generator$endBounds = function (properties) {
	var setBounds = F2(
		function (property, end) {
			switch (property.$) {
				case 0:
					var cssName = property.a;
					var unit = property.b;
					var config = property.c;
					return A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, config.n, unit, end);
				case 1:
					var cssName = property.a;
					var config = property.b;
					return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, config.n, end);
				case 2:
					var config = property.a;
					return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, config.n, end);
				case 3:
					var config = property.a;
					return A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
						config.E,
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, config.n, end));
				case 4:
					var config = property.a;
					return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, config.n, end);
				case 5:
					var config = property.a;
					return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, config.n, end);
				case 6:
					var config = property.a;
					return A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
						config.E,
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, config.n, end));
				case 7:
					var config = property.a;
					return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, config.n, end);
				default:
					var config = property.a;
					return A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits,
						config.E,
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, config.n, end));
			}
		});
	return A3($elm$core$List$foldl, setBounds, $author$project$Anim$Internal$Builder$PropertyBaselines$empty, properties);
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$AnimGroup = $elm$core$Basics$identity;
var $author$project$Anim$Extra$TransformOrder$Rotate = 1;
var $author$project$Anim$Extra$TransformOrder$Scale = 3;
var $author$project$Anim$Extra$TransformOrder$Skew = 2;
var $author$project$Anim$Extra$TransformOrder$Translate = 0;
var $author$project$Anim$Extra$TransformOrder$default = _List_fromArray(
	[0, 1, 2, 3]);
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$init = {A: 0, av: 0, cr: $elm$core$Dict$empty, cs: $elm$core$Dict$empty, t: $author$project$Anim$Internal$Builder$Once, X: 0, fq: $author$project$Anim$Internal$Builder$PropertyBaselines$empty, al: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, a6: $elm$core$Dict$empty, p: $author$project$Anim$Extra$TransformOrder$default};
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
var $author$project$Anim$Unit$Percent = 28;
var $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Anim$Internal$Builder$ProcessedOpacityConfig = function (a) {
	return {$: 2, a: a};
};
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
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$PerspectiveOrigin = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$default = {ar: 50, as: 50};
var $author$project$Anim$Internal$Property$Rotate$Rotate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Rotate$default = {ar: 0, as: 0, at: 0};
var $author$project$Anim$Internal$Property$Scale$Scale = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Scale$default = {ar: 1.0, as: 1.0, at: 1.0};
var $author$project$Anim$Internal$Property$Size$Size = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Size$default = {c2: 0, R: 0};
var $author$project$Anim$Internal$Property$Skew$Skew = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Skew$default = {ar: 0, as: 0};
var $author$project$Anim$Internal$Property$Translate$Translate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Translate$default = {ar: 0, as: 0, at: 0};
var $author$project$Anim$Unit$Px = 30;
var $author$project$Anim$Internal$Unit$default = 30;
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $author$project$Anim$Internal$Extra$Color$cleanHex = function (hex_) {
	return A2($elm$core$String$startsWith, '#', hex_) ? A2($elm$core$String$dropLeft, 1, hex_) : hex_;
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
	return {cR: b, c1: g, dy: r};
};
var $author$project$Anim$Internal$Extra$Color$floatMod = F2(
	function (a, b) {
		return a - ($elm$core$Basics$floor(a / b) * b);
	});
var $elm$core$Basics$round = _Basics_round;
var $author$project$Anim$Internal$Extra$Color$hslToRgb = function (hslValue) {
	var s = hslValue.dB / 100;
	var l = hslValue.dc / 100;
	var c = (1 - $elm$core$Basics$abs((2 * l) - 1)) * s;
	var m = l - (c / 2);
	var x = c * (1 - $elm$core$Basics$abs(
		A2($author$project$Anim$Internal$Extra$Color$floatMod, hslValue.c2 / 60, 2) - 1));
	var _v0 = (hslValue.c2 < 60) ? _Utils_Tuple3(c, x, 0) : ((hslValue.c2 < 120) ? _Utils_Tuple3(x, c, 0) : ((hslValue.c2 < 180) ? _Utils_Tuple3(0, c, x) : ((hslValue.c2 < 240) ? _Utils_Tuple3(0, x, c) : ((hslValue.c2 < 300) ? _Utils_Tuple3(x, 0, c) : _Utils_Tuple3(c, 0, x)))));
	var r1 = _v0.a;
	var g1 = _v0.b;
	var b1 = _v0.c;
	var b = $elm$core$Basics$round((b1 + m) * 255);
	var g = $elm$core$Basics$round((g1 + m) * 255);
	var r = $elm$core$Basics$round((r1 + m) * 255);
	return {cR: b, c1: g, dy: r};
};
var $avh4$elm_color$Color$toRgba = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	return {bK: a, cp: b, cv: g, cF: r};
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
			return {cR: rgba_.cR, c1: rgba_.c1, dy: rgba_.dy};
		case 3:
			var hsl_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(hsl_);
		case 4:
			var hsla_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(
				{c2: hsla_.c2, dc: hsla_.dc, dB: hsla_.dB});
		default:
			var elmColor_ = color.a;
			var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
			return {
				cR: $elm$core$Basics$round(rgba_.cp * 255),
				c1: $elm$core$Basics$round(rgba_.cv * 255),
				dy: $elm$core$Basics$round(rgba_.cF * 255)
			};
	}
};
var $author$project$Anim$Internal$Extra$Color$distance = F2(
	function (color1, color2) {
		var rgb2 = $author$project$Anim$Internal$Extra$Color$toRgb(color2);
		var rgb1 = $author$project$Anim$Internal$Extra$Color$toRgb(color1);
		var dr = rgb2.dy - rgb1.dy;
		var dg = rgb2.c1 - rgb1.c1;
		var db = rgb2.cR - rgb1.cR;
		return $elm$core$Basics$sqrt(((dr * dr) + (dg * dg)) + (db * db));
	});
var $author$project$Anim$Internal$Property$Opacity$distance = F2(
	function (_v0, _v1) {
		var o1 = _v0;
		var o2 = _v1;
		return $elm$core$Basics$abs(o2 - o1);
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple = function (_v0) {
	var y = _v0.as;
	var x = _v0.ar;
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
		var record2 = support.f5(coord2);
		var record1 = support.f5(coord1);
		var dz = $elm$core$Basics$abs(record2.at - record1.at);
		var dy = $elm$core$Basics$abs(record2.as - record1.as);
		var dx = $elm$core$Basics$abs(record2.ar - record1.ar);
		return A2(
			$elm$core$Basics$max,
			dx,
			A2($elm$core$Basics$max, dy, dz));
	});
var $author$project$Anim$Internal$Property$Rotate$support = {
	dT: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ar: a.ar + b.ar, as: a.as + b.as, at: a.at + b.at};
		}),
	ey: $author$project$Anim$Internal$Property$Rotate$default,
	eN: $elm$core$Basics$identity,
	ca: F2(
		function (factor, _v2) {
			var angles = _v2;
			return {ar: angles.ar * factor, as: angles.as * factor, at: angles.at * factor};
		}),
	fO: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ar: a.ar - b.ar, as: a.as - b.as, at: a.at - b.at};
		}),
	f5: function (_v5) {
		var angles = _v5;
		return angles;
	}
};
var $author$project$Anim$Internal$Property$Rotate$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Property$Scale$support = {
	dT: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ar: a.ar + b.ar, as: a.as + b.as, at: a.at + b.at};
		}),
	ey: $author$project$Anim$Internal$Property$Scale$default,
	eN: $elm$core$Basics$identity,
	ca: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {ar: coords.ar * factor, as: coords.as * factor, at: coords.at * factor};
		}),
	fO: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ar: a.ar - b.ar, as: a.as - b.as, at: a.at - b.at};
		}),
	f5: function (_v5) {
		var coords = _v5;
		return coords;
	}
};
var $author$project$Anim$Internal$Property$Scale$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Size$distance = F2(
	function (_v0, _v1) {
		var start = _v0;
		var end = _v1;
		var dw = end.R - start.R;
		var dh = end.c2 - start.c2;
		return $elm$core$Basics$sqrt((dw * dw) + (dh * dh));
	});
var $author$project$Anim$Internal$Property$Skew$toTuple = function (_v0) {
	var values = _v0;
	return _Utils_Tuple2(values.ar, values.as);
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
	dT: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {ar: a.ar + b.ar, as: a.as + b.as, at: a.at + b.at};
		}),
	ey: $author$project$Anim$Internal$Property$Translate$default,
	eN: $elm$core$Basics$identity,
	ca: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {ar: coords.ar * factor, as: coords.as * factor, at: coords.at * factor};
		}),
	fO: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {ar: a.ar - b.ar, as: a.as - b.as, at: a.at - b.at};
		}),
	f5: function (_v5) {
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
var $author$project$Anim$Internal$Property$Opacity$Opacity = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Opacity$fromFloat = function (o) {
	return o;
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
				ar: A2($author$project$Anim$Internal$Unit$orMaybe, axes.ar, baseline.ar),
				as: A2($author$project$Anim$Internal$Unit$orMaybe, axes.as, baseline.as),
				at: A2($author$project$Anim$Internal$Unit$orMaybe, axes.at, baseline.at)
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
			ar: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.ar, store),
			as: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.as, store),
			at: A3($author$project$Anim$Internal$Builder$CssUnitStore$get, group, slots.at, store)
		};
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginX = 'perspectiveOrigin.x';
var $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginY = 'perspectiveOrigin.y';
var $author$project$Anim$Internal$Builder$perspectiveOriginStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ar: $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginX, as: $author$project$Anim$Internal$Builder$CssUnitStore$perspectiveOriginY, at: ''},
			defaults.ab);
	});
var $author$project$Shared$TimeSpec$Duration = function (a) {
	return {$: 0, a: a};
};
var $author$project$Motion$Easing$EaseInOut = {$: 16};
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
			ar: A3($author$project$Anim$Internal$Unit$pickAxis, local.ar, global.ar, default_),
			as: A3($author$project$Anim$Internal$Unit$pickAxis, local.as, global.as, default_),
			at: A3($author$project$Anim$Internal$Unit$pickAxis, local.at, global.at, default_)
		};
	});
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
var $author$project$Shared$Spring$Critically = function (a) {
	return {$: 1, a: a};
};
var $author$project$Shared$Spring$Overdamped = function (a) {
	return {$: 2, a: a};
};
var $author$project$Shared$Spring$Underdamped = function (a) {
	return {$: 0, a: a};
};
var $author$project$Shared$Spring$precompute = function (_v0) {
	var to = _v0.cg;
	var from = _v0.bX;
	var spring = _v0.by;
	var x0 = from - to;
	var v0 = spring.bj;
	var m = A2($elm$core$Basics$max, 1.0e-6, spring.a0);
	var k = A2($elm$core$Basics$max, 0, spring.a7);
	var omega0 = $elm$core$Basics$sqrt(k / m);
	var c = A2($elm$core$Basics$max, 0, spring.aY);
	var zeta = (k <= 0) ? 1.0 : (c / (2.0 * $elm$core$Basics$sqrt(k * m)));
	if ($elm$core$Basics$abs(zeta - 1.0) < 1.0e-4) {
		return $author$project$Shared$Spring$Critically(
			{cN: x0, cR: v0 + (omega0 * x0), aj: omega0});
	} else {
		if (zeta < 1.0) {
			var omegaD = omega0 * $elm$core$Basics$sqrt(1.0 - (zeta * zeta));
			return $author$project$Shared$Spring$Underdamped(
				{cN: x0, cR: (v0 + ((zeta * omega0) * x0)) / omegaD, aj: omega0, b1: omegaD, bJ: zeta});
		} else {
			var disc = $elm$core$Basics$sqrt((zeta * zeta) - 1.0);
			var r1 = (-omega0) * (zeta - disc);
			var r2 = (-omega0) * (zeta + disc);
			var a = (v0 - (r2 * x0)) / (r1 - r2);
			return $author$project$Shared$Spring$Overdamped(
				{cN: a, cR: x0 - a, bw: r1, bx: r2});
		}
	}
};
var $elm$core$Basics$e = _Basics_e;
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
			var b = sol.a.cR;
			var a = sol.a.cN;
			var zeta = sol.a.bJ;
			var omega0 = sol.a.aj;
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
			var b = sol.a.cR;
			var a = sol.a.cN;
			var omega0 = sol.a.aj;
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
			var b = sol.a.cR;
			var a = sol.a.cN;
			var r2 = sol.a.bx;
			var r1 = sol.a.bw;
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
var $author$project$Motion$Internal$Spring$unwrap = function (_v0) {
	var config = _v0;
	return config;
};
var $author$project$Anim$Internal$Builder$processStandardAnimation = function (_v0) {
	var wrapper = _v0.aq;
	var speedFn = _v0.ao;
	var durationFn = _v0.af;
	var distanceFn = _v0.ae;
	var defaultCssUnit = _v0.ac;
	var defaultStart = _v0.ad;
	var globalCssUnit = _v0.i;
	var globalData = _v0.ag;
	var config = _v0.I;
	var start = A2($elm$core$Maybe$withDefault, defaultStart, config.bz);
	var resolvedTiming = A3(
		$author$project$Anim$Internal$Builder$resolveTimingWithDefault,
		config.cf,
		globalData.ah,
		$author$project$Shared$TimeSpec$Duration(0));
	var resolvedSpring = config.by;
	var distance_ = A2(distanceFn, start, config.n);
	var rawDuration = A2(durationFn, distance_, resolvedTiming);
	var duration_ = function () {
		if (!resolvedSpring.$) {
			var s = resolvedSpring.a;
			return $author$project$Shared$Spring$settleTimeMs(
				{
					bX: 0,
					by: $author$project$Motion$Internal$Spring$unwrap(s),
					cg: 1
				});
		} else {
			return rawDuration;
		}
	}();
	var speed_ = A3(speedFn, distance_, duration_, resolvedTiming);
	return wrapper(
		{
			E: A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, config.E, globalCssUnit, defaultCssUnit),
			v: A3($author$project$Anim$Internal$Builder$resolveDelayWithDefault, config.v, $elm$core$Maybe$Nothing, 0),
			ct: distance_,
			y: $elm$core$Basics$round(duration_),
			bW: A3($author$project$Anim$Internal$Builder$resolveEasingWithDefault, config.bW, $elm$core$Maybe$Nothing, $author$project$Motion$Easing$EaseInOut),
			n: config.n,
			Q: config.Q,
			dF: speed_,
			by: resolvedSpring,
			bz: config.bz,
			cf: resolvedTiming
		});
};
var $author$project$Anim$Internal$Builder$CssUnitStore$sizeHeight = 'size.height';
var $author$project$Anim$Internal$Builder$CssUnitStore$sizeWidth = 'size.width';
var $author$project$Anim$Internal$Builder$sizeStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ar: $author$project$Anim$Internal$Builder$CssUnitStore$sizeWidth, as: $author$project$Anim$Internal$Builder$CssUnitStore$sizeHeight, at: ''},
			defaults.ab);
	});
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
var $author$project$Anim$Internal$Builder$CssUnitStore$translateX = 'translate.x';
var $author$project$Anim$Internal$Builder$CssUnitStore$translateY = 'translate.y';
var $author$project$Anim$Internal$Builder$CssUnitStore$translateZ = 'translate.z';
var $author$project$Anim$Internal$Builder$translateStoreAxes = F2(
	function (defaults, animGroupName) {
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			animGroupName,
			{ar: $author$project$Anim$Internal$Builder$CssUnitStore$translateX, as: $author$project$Anim$Internal$Builder$CssUnitStore$translateY, at: $author$project$Anim$Internal$Builder$CssUnitStore$translateZ},
			defaults.ab);
	});
var $author$project$Anim$Internal$Extra$Color$Rgba = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Extra$Color$transparent = $author$project$Anim$Internal$Extra$Color$Rgba(
	{cN: 0, cR: 255, c1: 255, dy: 255});
var $author$project$Anim$Internal$Builder$processProperty = F3(
	function (globalData, animGroupName, property) {
		var mergeTranslate = function (cfg) {
			return _Utils_update(
				cfg,
				{
					E: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$translateStoreAxes, globalData, animGroupName)),
						cfg.E)
				});
		};
		var mergeSize = function (cfg) {
			return _Utils_update(
				cfg,
				{
					E: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$sizeStoreAxes, globalData, animGroupName)),
						cfg.E)
				});
		};
		var mergePerspectiveOrigin = function (cfg) {
			return _Utils_update(
				cfg,
				{
					E: A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						$elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Builder$perspectiveOriginStoreAxes, globalData, animGroupName)),
						cfg.E)
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
							I: config,
							ac: $author$project$Anim$Internal$Unit$default,
							ad: 0,
							ae: F2(
								function (a, b) {
									return $elm$core$Basics$abs(b - a);
								}),
							af: $author$project$Shared$TimeSpec$duration,
							i: globalData.i,
							ag: globalData,
							ao: $author$project$Shared$TimeSpec$speed,
							aq: A2($author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig, cssName, unit)
						}));
			case 1:
				var cssName = property.a;
				var config = property.b;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							I: config,
							ac: $author$project$Anim$Internal$Unit$default,
							ad: $author$project$Anim$Internal$Extra$Color$transparent,
							ae: $author$project$Anim$Internal$Extra$Color$distance,
							af: $author$project$Anim$Internal$Extra$Color$duration,
							i: globalData.i,
							ag: globalData,
							ao: $author$project$Anim$Internal$Extra$Color$speed,
							aq: $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig(cssName)
						}));
			case 2:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							I: config,
							ac: $author$project$Anim$Internal$Unit$default,
							ad: $author$project$Anim$Internal$Property$Opacity$fromFloat(1.0),
							ae: $author$project$Anim$Internal$Property$Opacity$distance,
							af: $author$project$Anim$Internal$Property$Opacity$duration,
							i: globalData.i,
							ag: globalData,
							ao: $author$project$Anim$Internal$Property$Opacity$speed,
							aq: $author$project$Anim$Internal$Builder$ProcessedOpacityConfig
						}));
			case 3:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							I: mergePerspectiveOrigin(config),
							ac: 28,
							ad: $author$project$Anim$Internal$Property$PerspectiveOrigin$default,
							ae: $author$project$Anim$Internal$Property$PerspectiveOrigin$distance,
							af: $author$project$Anim$Internal$Property$PerspectiveOrigin$duration,
							i: globalData.i,
							ag: globalData,
							ao: $author$project$Anim$Internal$Property$PerspectiveOrigin$speed,
							aq: $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig
						}));
			case 4:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{I: config, ac: $author$project$Anim$Internal$Unit$default, ad: $author$project$Anim$Internal$Property$Rotate$default, ae: $author$project$Anim$Internal$Property$Rotate$distance, af: $author$project$Anim$Internal$Property$Rotate$duration, i: globalData.i, ag: globalData, ao: $author$project$Anim$Internal$Property$Rotate$speed, aq: $author$project$Anim$Internal$Builder$ProcessedRotateConfig}));
			case 5:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{I: config, ac: $author$project$Anim$Internal$Unit$default, ad: $author$project$Anim$Internal$Property$Scale$default, ae: $author$project$Anim$Internal$Property$Scale$distance, af: $author$project$Anim$Internal$Property$Scale$duration, i: globalData.i, ag: globalData, ao: $author$project$Anim$Internal$Property$Scale$speed, aq: $author$project$Anim$Internal$Builder$ProcessedScaleConfig}));
			case 6:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							I: mergeSize(config),
							ac: $author$project$Anim$Internal$Unit$default,
							ad: $author$project$Anim$Internal$Property$Size$default,
							ae: $author$project$Anim$Internal$Property$Size$distance,
							af: $author$project$Anim$Internal$Property$Size$duration,
							i: globalData.Z,
							ag: globalData,
							ao: $author$project$Anim$Internal$Property$Size$speed,
							aq: $author$project$Anim$Internal$Builder$ProcessedSizeConfig
						}));
			case 7:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{I: config, ac: $author$project$Anim$Internal$Unit$default, ad: $author$project$Anim$Internal$Property$Skew$default, ae: $author$project$Anim$Internal$Property$Skew$distance, af: $author$project$Anim$Internal$Property$Skew$duration, i: globalData.i, ag: globalData, ao: $author$project$Anim$Internal$Property$Skew$speed, aq: $author$project$Anim$Internal$Builder$ProcessedSkewConfig}));
			default:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							I: mergeTranslate(config),
							ac: $author$project$Anim$Internal$Unit$default,
							ad: $author$project$Anim$Internal$Property$Translate$default,
							ae: $author$project$Anim$Internal$Property$Translate$distance,
							af: $author$project$Anim$Internal$Property$Translate$duration,
							i: globalData.i,
							ag: globalData,
							ao: $author$project$Anim$Internal$Property$Translate$speed,
							aq: $author$project$Anim$Internal$Builder$ProcessedTranslateConfig
						}));
		}
	});
var $author$project$Anim$Internal$Builder$processProperties = F2(
	function (defaults, animGroupName) {
		return $elm$core$List$filterMap(
			A2($author$project$Anim$Internal$Builder$processProperty, defaults, animGroupName));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteEntry = F2(
	function (entry, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{cr: entry});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteExit = F2(
	function (exit, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{cs: exit});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot = F2(
	function (snapshot, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{fq: snapshot});
	});
var $author$project$Anim$Internal$Engine$WAAPI$Generator$init = F5(
	function (defaults, animGroupName, discreteEntryProps, discreteExitProps, properties) {
		var processedProps = A3($author$project$Anim$Internal$Builder$processProperties, defaults, animGroupName, properties);
		return A2(
			$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteExit,
			discreteExitProps,
			A2(
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteEntry,
				discreteEntryProps,
				A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot,
					$author$project$Anim$Internal$Engine$WAAPI$Generator$endBounds(processedProps),
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$init)));
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
var $author$project$Anim$Internal$Builder$extractPerspectiveOriginCssUnit = function (propConfig) {
	if (propConfig.$ === 3) {
		var cfg = propConfig.a;
		return cfg.E;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
var $author$project$Anim$Internal$Builder$extractSizeCssUnit = function (propConfig) {
	if (propConfig.$ === 6) {
		var cfg = propConfig.a;
		return cfg.E;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
var $author$project$Anim$Internal$Builder$extractTranslateCssUnit = function (propConfig) {
	if (propConfig.$ === 8) {
		var cfg = propConfig.a;
		return cfg.E;
	} else {
		return $author$project$Anim$Internal$Unit$emptyCssUnitAxes;
	}
};
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
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.i, $author$project$Anim$Internal$Unit$default),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, cfg.n, baselines)));
			case 4:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, cfg.n, baselines);
			case 5:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, cfg.n, baselines);
			case 7:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, cfg.n, baselines);
			case 2:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, cfg.n, baselines);
			case 3:
				var cfg = propConfig.a;
				var merged = perspectiveOriginUnits(0);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginConfiguredUnits,
					merged,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.i, 28),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, cfg.n, baselines)));
			case 6:
				var cfg = propConfig.a;
				var merged = sizeUnits(0);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeConfiguredUnits,
					merged,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
						A3($author$project$Anim$Internal$Unit$resolveCssUnitAxes, merged, defaults.Z, $author$project$Anim$Internal$Unit$default),
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, cfg.n, baselines)));
			case 0:
				var cssName = propConfig.a;
				var unit = propConfig.b;
				var cfg = propConfig.c;
				return A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, cfg.n, unit, baselines);
			default:
				var cssName = propConfig.a;
				var cfg = propConfig.b;
				return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, cfg.n, baselines);
		}
	});
var $author$project$Anim$Internal$Builder$extractBaselinesFromConfig = F3(
	function (defaults, animGroupName, elementConfig) {
		return A3(
			$elm$core$List$foldl,
			A2($author$project$Anim$Internal$Builder$extractPropertyBaseline, defaults, animGroupName),
			$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
			elementConfig.s);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$insert = F3(
	function (name, value, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, name, value, dict);
	});
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
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
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
var $author$project$Anim$Internal$Builder$mergeBaselines = function (_v0) {
	var data = _v0;
	var defaults = data.c;
	var animation = data.a;
	var state = data.x;
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
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, groupName, animation.W));
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
		animation.C);
	var newState = _Utils_update(
		state,
		{
			S: A6(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$merge,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				mergeBoth,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(newBaselines),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.S),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$init)
		});
	return _Utils_update(
		data,
		{x: newState});
};
var $author$project$Anim$Internal$Engine$WAAPI$init = F3(
	function (commandPort, subscriptionPort, propertyInitializers) {
		if (!propertyInitializers.b) {
			return A2(
				$author$project$Anim$Internal$Engine$WAAPI$AnimState,
				{
					q: $author$project$Anim$Internal$Builder$init(_List_Nil),
					M: commandPort,
					bu: $elm$core$Dict$empty,
					cJ: subscriptionPort,
					_: false
				},
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
		} else {
			var builder = $author$project$Anim$Internal$Builder$init(propertyInitializers);
			var initGroup = F2(
				function (animGroupName, _v1) {
					var properties = _v1.s;
					return A5(
						$author$project$Anim$Internal$Engine$WAAPI$Generator$init,
						$author$project$Anim$Internal$Builder$getDefaults(builder),
						animGroupName,
						A2($author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor, animGroupName, builder),
						A2($author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor, animGroupName, builder),
						properties);
				});
			var animGroups = $author$project$Anim$Internal$Builder$getAnimGroups(builder);
			return A2(
				$author$project$Anim$Internal$Engine$WAAPI$AnimState,
				{
					q: $author$project$Anim$Internal$Builder$clearAnimData(
						$author$project$Anim$Internal$Builder$mergeBaselines(builder)),
					M: commandPort,
					bu: $elm$core$Dict$empty,
					cJ: subscriptionPort,
					_: false
				},
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, initGroup, animGroups));
		}
	});
var $author$project$Anim$Engine$WAAPI$init = $author$project$Anim$Internal$Engine$WAAPI$init;
var $author$project$Anim$Internal$Builder$unitTargetGroup = F2(
	function (data, initGroup) {
		var _v0 = data.a.r;
		if (!_v0.$) {
			var animGroupName = _v0.a;
			return $elm$core$Maybe$Just(animGroupName);
		} else {
			return initGroup;
		}
	});
var $author$project$Anim$Internal$Builder$CssUnitStore$set = F3(
	function (group, slot, unit) {
		return A2(
			$elm$core$Dict$insert,
			_Utils_Tuple2(group, slot),
			unit);
	});
var $author$project$Anim$Internal$Builder$writeCssUnitForGroup = F4(
	function (maybeGroup, slot, unit, _v0) {
		var data = _v0;
		if (maybeGroup.$ === 1) {
			return data;
		} else {
			var group = maybeGroup.a;
			var defs = data.c;
			var animation = data.a;
			return _Utils_update(
				data,
				{
					a: _Utils_update(
						animation,
						{
							aX: A4($author$project$Anim$Internal$Builder$CssUnitStore$set, group, slot, unit, animation.aX)
						}),
					c: _Utils_update(
						defs,
						{
							ab: A4($author$project$Anim$Internal$Builder$CssUnitStore$set, group, slot, unit, defs.ab)
						})
				});
		}
	});
var $author$project$Anim$Internal$Builder$setTranslateInitCssUnitY = F2(
	function (unit, builder) {
		var data = builder;
		return A4(
			$author$project$Anim$Internal$Builder$writeCssUnitForGroup,
			A2($author$project$Anim$Internal$Builder$unitTargetGroup, data, data.c.aA),
			$author$project$Anim$Internal$Builder$CssUnitStore$translateY,
			unit,
			builder);
	});
var $author$project$Anim$Property$Translate$initCssUnitY = $author$project$Anim$Internal$Builder$setTranslateInitCssUnitY;
var $author$project$Anim$Internal$Builder$TranslateConfig = function (a) {
	return {$: 8, a: a};
};
var $elm$core$Basics$clamp = F3(
	function (low, high, number) {
		return (_Utils_cmp(number, low) < 0) ? low : ((_Utils_cmp(number, high) > 0) ? high : number);
	});
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
var $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple = F2(
	function (support, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		var z = _v0.c;
		return support.eN(
			{ar: x, as: y, at: z});
	});
var $author$project$Anim$Internal$Property$Translate$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Builder$getClamp = F4(
	function (animGroupName, propertyKey, axis, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Dict$get,
			_Utils_Tuple3(animGroupName, propertyKey, axis),
			data.x.a4);
	});
var $author$project$Anim$Internal$Builder$getCurrentAnimGroupName = function (_v0) {
	var data = _v0;
	return data.a.r;
};
var $author$project$Anim$Internal$Property$Translate$getX = function (_v0) {
	var coords = _v0;
	return coords.ar;
};
var $author$project$Anim$Internal$Property$Translate$getY = function (_v0) {
	var coords = _v0;
	return coords.as;
};
var $author$project$Anim$Internal$Property$Translate$getZ = function (_v0) {
	var coords = _v0;
	return coords.at;
};
var $author$project$Anim$Internal$Builder$Translate$applyClamps = F2(
	function (builder, config) {
		var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(builder);
		if (_v0.$ === 1) {
			return config;
		} else {
			var animGroupName = _v0.a;
			var cz = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'translate', 'z', builder);
			var cy = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'translate', 'y', builder);
			var cx = A4($author$project$Anim$Internal$Builder$getClamp, animGroupName, 'translate', 'x', builder);
			if (_Utils_eq(cx, $elm$core$Maybe$Nothing) && (_Utils_eq(cy, $elm$core$Maybe$Nothing) && _Utils_eq(cz, $elm$core$Maybe$Nothing))) {
				return config;
			} else {
				var clampValue = function (value) {
					return $author$project$Anim$Internal$Property$Translate$fromTriple(
						_Utils_Tuple3(
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cx,
								$author$project$Anim$Internal$Property$Translate$getX(value)),
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cy,
								$author$project$Anim$Internal$Property$Translate$getY(value)),
							A2(
								$author$project$Anim$Internal$Builder$Property$clampAxis,
								cz,
								$author$project$Anim$Internal$Property$Translate$getZ(value))));
				};
				var clampedEnd = clampValue(config.n);
				var clampedStart = A2($elm$core$Maybe$map, clampValue, config.bz);
				var startForDistance = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Translate$default, clampedStart);
				return _Utils_update(
					config,
					{
						ct: A2($author$project$Anim$Internal$Property$Translate$distance, startForDistance, clampedEnd),
						n: clampedEnd,
						bz: clampedStart
					});
			}
		}
	});
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Anim$Internal$Builder$getFrozenAxes = F2(
	function (propName, _v0) {
		var data = _v0;
		var _v1 = data.a.r;
		if (_v1.$ === 1) {
			return A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2($elm$core$Dict$get, propName, data.a.e));
		} else {
			var animGroupName = _v1.a;
			var fromGroup = A2(
				$elm$core$Maybe$andThen,
				$elm$core$Dict$get(propName),
				A2(
					$elm$core$Maybe$andThen,
					function ($) {
						return $.e;
					},
					A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.C)));
			var fromGlobal = A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2($elm$core$Dict$get, propName, data.a.e));
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
var $author$project$Anim$Internal$Builder$Property$applyFrozenAxes = F6(
	function (propertyName, toRec, fromRec, calcDistance, builder, config) {
		var frozenAxes = A2($author$project$Anim$Internal$Builder$getFrozenAxes, propertyName, builder);
		if ($elm$core$List$isEmpty(frozenAxes)) {
			return config;
		} else {
			var _v0 = config.bz;
			if (_v0.$ === 1) {
				return config;
			} else {
				var startVal = _v0.a;
				var startRecord = toRec(startVal);
				var endRecord = toRec(config.n);
				var end = fromRec(
					{
						ar: A2($elm$core$List$member, 'x', frozenAxes) ? startRecord.ar : endRecord.ar,
						as: A2($elm$core$List$member, 'y', frozenAxes) ? startRecord.as : endRecord.as,
						at: A2($elm$core$List$member, 'z', frozenAxes) ? startRecord.at : endRecord.at
					});
				return _Utils_update(
					config,
					{
						ct: A2(calcDistance, startVal, end),
						n: end
					});
			}
		}
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord = function (support) {
	return support.eN;
};
var $author$project$Anim$Internal$Property$Translate$fromRecord = $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Property$Shared$Axis3$toRecord = function (support) {
	return support.f5;
};
var $author$project$Anim$Internal$Property$Translate$toRecord = $author$project$Anim$Internal$Property$Shared$Axis3$toRecord($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig = function (_v0) {
	var data = _v0;
	var _v1 = data.a.r;
	if (_v1.$ === 1) {
		return {
			f: $elm$core$Maybe$Just(data.b.f),
			g: $elm$core$Maybe$Just(data.b.g),
			h: $elm$core$Maybe$Nothing,
			e: $elm$core$Maybe$Just(data.a.e),
			b: $elm$core$Maybe$Nothing,
			s: _List_Nil,
			p: data.c.aJ,
			j: $elm$core$Maybe$Just(data.j),
			k: data.o.k,
			l: data.o.l
		};
	} else {
		var animGroupName = _v1.a;
		return A2(
			$elm$core$Maybe$withDefault,
			{
				f: $elm$core$Maybe$Just(data.b.f),
				g: $elm$core$Maybe$Just(data.b.g),
				h: $elm$core$Maybe$Nothing,
				e: $elm$core$Maybe$Just(data.a.e),
				b: $elm$core$Maybe$Nothing,
				s: _List_Nil,
				p: data.c.aJ,
				j: $elm$core$Maybe$Just(data.j),
				k: data.o.k,
				l: data.o.l
			},
			A2(
				$elm$core$Maybe$map,
				function (config) {
					return _Utils_update(
						config,
						{
							f: function () {
								var _v2 = config.f;
								if (!_v2.$) {
									var groupDiscreteEntry = _v2.a;
									return $elm$core$Maybe$Just(groupDiscreteEntry);
								} else {
									return $elm$core$Maybe$Just(data.b.f);
								}
							}(),
							g: function () {
								var _v3 = config.g;
								if (!_v3.$) {
									var groupDiscreteExit = _v3.a;
									return $elm$core$Maybe$Just(groupDiscreteExit);
								} else {
									return $elm$core$Maybe$Just(data.b.g);
								}
							}(),
							e: function () {
								var _v4 = config.e;
								if (!_v4.$) {
									var groupFrozenAxes = _v4.a;
									return $elm$core$Maybe$Just(groupFrozenAxes);
								} else {
									return $elm$core$Maybe$Just(data.a.e);
								}
							}(),
							p: function () {
								var _v5 = config.p;
								if (!_v5.$) {
									var groupOrder = _v5.a;
									return $elm$core$Maybe$Just(groupOrder);
								} else {
									return data.c.aJ;
								}
							}(),
							j: function () {
								var _v6 = config.j;
								if (!_v6.$) {
									var groupThrottleMs = _v6.a;
									return $elm$core$Maybe$Just(groupThrottleMs);
								} else {
									return $elm$core$Maybe$Just(data.j);
								}
							}(),
							k: function () {
								var _v7 = config.k;
								if (!_v7.$) {
									var groupRangeEnd = _v7.a;
									return $elm$core$Maybe$Just(groupRangeEnd);
								} else {
									return data.o.k;
								}
							}(),
							l: function () {
								var _v8 = config.l;
								if (!_v8.$) {
									var groupRangeStart = _v8.a;
									return $elm$core$Maybe$Just(groupRangeStart);
								} else {
									return data.o.l;
								}
							}()
						});
				},
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.C)));
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
var $author$project$Anim$Internal$Builder$updateCurrentConfig = F2(
	function (config, _v0) {
		var data = _v0;
		var _v1 = data.a.r;
		if (_v1.$ === 1) {
			return data;
		} else {
			var animKey = _v1.a;
			var configWithDiscreteSnapshot = _Utils_update(
				config,
				{
					f: function () {
						var _v16 = config.f;
						if (!_v16.$) {
							return config.f;
						} else {
							return $elm$core$Maybe$Just(data.b.f);
						}
					}(),
					g: function () {
						var _v17 = config.g;
						if (!_v17.$) {
							return config.g;
						} else {
							return $elm$core$Maybe$Just(data.b.g);
						}
					}()
				});
			var newPropertyTypes = A2($elm$core$List$map, $author$project$Anim$Internal$Builder$propertyType, configWithDiscreteSnapshot.s);
			var anim = data.a;
			var mergedConfig = function () {
				var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animKey, anim.C);
				if (!_v2.$) {
					var existing = _v2.a;
					var mergedOrder = function () {
						var _v15 = configWithDiscreteSnapshot.p;
						if (!_v15.$) {
							return configWithDiscreteSnapshot.p;
						} else {
							return existing.p;
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
						existing.s);
					return _Utils_update(
						existing,
						{
							f: function () {
								var _v3 = configWithDiscreteSnapshot.f;
								if (!_v3.$) {
									var newDiscreteEntry = _v3.a;
									return $elm$core$Maybe$Just(
										A2(
											$elm$core$Dict$union,
											newDiscreteEntry,
											A2($elm$core$Maybe$withDefault, $elm$core$Dict$empty, existing.f)));
								} else {
									return existing.f;
								}
							}(),
							g: function () {
								var _v4 = configWithDiscreteSnapshot.g;
								if (!_v4.$) {
									var newDiscreteExit = _v4.a;
									return $elm$core$Maybe$Just(
										A2(
											$elm$core$Dict$union,
											newDiscreteExit,
											A2($elm$core$Maybe$withDefault, $elm$core$Dict$empty, existing.g)));
								} else {
									return existing.g;
								}
							}(),
							h: function () {
								var _v5 = configWithDiscreteSnapshot.h;
								if (!_v5.$) {
									return configWithDiscreteSnapshot.h;
								} else {
									return existing.h;
								}
							}(),
							e: function () {
								var _v6 = configWithDiscreteSnapshot.e;
								if (!_v6.$) {
									return configWithDiscreteSnapshot.e;
								} else {
									return existing.e;
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
												A: function () {
													var _v8 = incomingPlayback.A;
													if (!_v8.$) {
														return incomingPlayback.A;
													} else {
														return existingPlayback.A;
													}
												}(),
												t: function () {
													var _v9 = incomingPlayback.t;
													if (!_v9.$) {
														return incomingPlayback.t;
													} else {
														return existingPlayback.t;
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
							s: _Utils_ap(filteredExisting, configWithDiscreteSnapshot.s),
							p: mergedOrder,
							j: function () {
								var _v12 = configWithDiscreteSnapshot.j;
								if (!_v12.$) {
									return configWithDiscreteSnapshot.j;
								} else {
									return existing.j;
								}
							}(),
							k: function () {
								var _v13 = configWithDiscreteSnapshot.k;
								if (!_v13.$) {
									return configWithDiscreteSnapshot.k;
								} else {
									return existing.k;
								}
							}(),
							l: function () {
								var _v14 = configWithDiscreteSnapshot.l;
								if (!_v14.$) {
									return configWithDiscreteSnapshot.l;
								} else {
									return existing.l;
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
							C: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animKey, mergedConfig, anim.C),
							W: A3(
								$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
								animKey,
								function (maybeDefaults) {
									return $elm$core$Maybe$Just(
										A2($elm$core$Maybe$withDefault, data.c, maybeDefaults));
								},
								anim.W)
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
					s: _Utils_ap(
						config.s,
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
				return $.s;
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
				config.s),
			_List_fromArray(
				[propertyConfig]));
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			_Utils_update(
				config,
				{s: properties}),
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
var $author$project$Anim$Internal$Builder$Translate$build = function (_v0) {
	var config = _v0.a;
	var builder = _v0.b;
	var clampedConfig = A2($author$project$Anim$Internal$Builder$Translate$applyClamps, builder, config);
	return A2(
		$author$project$Anim$Internal$Builder$Property$upsert,
		$author$project$Anim$Internal$Builder$TranslateConfig(
			A6($author$project$Anim$Internal$Builder$Property$applyFrozenAxes, 'translate', $author$project$Anim$Internal$Property$Translate$toRecord, $author$project$Anim$Internal$Property$Translate$fromRecord, $author$project$Anim$Internal$Property$Translate$distance, builder, clampedConfig)),
		builder);
};
var $author$project$Anim$Internal$Builder$Translate$TranslateBuilder = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$Animate = {$: 0};
var $author$project$Anim$Internal$Builder$Property$defaultConfig = function (defaultEnd) {
	return {E: $author$project$Anim$Internal$Unit$emptyCssUnitAxes, v: $elm$core$Maybe$Nothing, ct: 0, bW: $elm$core$Maybe$Nothing, n: defaultEnd, Q: $author$project$Anim$Internal$Builder$Animate, by: $elm$core$Maybe$Nothing, bz: $elm$core$Maybe$Nothing, cf: $elm$core$Maybe$Nothing};
};
var $author$project$Anim$Internal$Builder$Translate$defaultConfig = $author$project$Anim$Internal$Builder$Property$defaultConfig($author$project$Anim$Internal$Property$Translate$default);
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
			anim.W);
		return _Utils_update(
			data,
			{
				a: _Utils_update(
					anim,
					{
						r: $elm$core$Maybe$Just(elementId),
						W: groupDefaults
					})
			});
	});
var $author$project$Anim$Internal$Builder$getScopedDefaults = function (_v0) {
	var data = _v0;
	var _v1 = data.a.r;
	if (_v1.$ === 1) {
		return data.c;
	} else {
		var animGroupName = _v1.a;
		return A2(
			$elm$core$Maybe$withDefault,
			data.c,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.a.W));
	}
};
var $author$project$Anim$Internal$Builder$getDelay = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).aH;
};
var $author$project$Anim$Internal$Builder$getEasing = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).ax;
};
var $author$project$Anim$Internal$Builder$getSpring = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).aI;
};
var $author$project$Anim$Internal$Builder$getTimeSpec = function (_v0) {
	var data = _v0;
	return $author$project$Anim$Internal$Builder$getScopedDefaults(data).ah;
};
var $author$project$Anim$Internal$Builder$Property$applyGlobalDefaults = F2(
	function (builder, config) {
		return _Utils_update(
			config,
			{
				v: function () {
					var _v0 = config.v;
					if (!_v0.$) {
						var delay_ = _v0.a;
						return $elm$core$Maybe$Just(delay_);
					} else {
						return $author$project$Anim$Internal$Builder$getDelay(builder);
					}
				}(),
				bW: function () {
					var _v1 = config.bW;
					if (!_v1.$) {
						var easing_ = _v1.a;
						return $elm$core$Maybe$Just(easing_);
					} else {
						return $author$project$Anim$Internal$Builder$getEasing(builder);
					}
				}(),
				by: function () {
					var _v2 = config.by;
					if (!_v2.$) {
						var spring_ = _v2.a;
						return $elm$core$Maybe$Just(spring_);
					} else {
						return $author$project$Anim$Internal$Builder$getSpring(builder);
					}
				}(),
				cf: function () {
					var _v3 = config.cf;
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
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.x.S);
	});
var $author$project$Anim$Internal$Builder$getRuntimeBaseline = F2(
	function (key, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.x.b9);
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
					return $.s;
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
						v: $elm$core$Maybe$Nothing,
						ct: 0,
						bW: $elm$core$Maybe$Nothing,
						n: config.n,
						by: $elm$core$Maybe$Nothing,
						bz: $elm$core$List$head(
							A2(
								$elm$core$List$filterMap,
								$elm$core$Basics$identity,
								_List_fromArray(
									[
										runtimeValue,
										baselineValue,
										$elm$core$Maybe$Just(config.n)
									]))),
						cf: $elm$core$Maybe$Nothing
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
								n: baseline,
								bz: $elm$core$Maybe$Just(runtime)
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
								n: runtime,
								bz: $elm$core$Maybe$Just(runtime)
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
								n: baseline,
								bz: $elm$core$Maybe$Just(baseline)
							}));
				} else {
					var _v5 = _v2.a;
					var _v6 = _v2.b;
					return A2($author$project$Anim$Internal$Builder$Property$applyGlobalDefaults, builder, defaultConfig_);
				}
			}
		}
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 12) {
				var t = v.a;
				return $elm$core$Maybe$Just(t);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'translate', dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslateConfiguredUnits = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 14) {
				var u = v.a;
				return $elm$core$Maybe$Just(u);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'translateConfiguredUnits', dict));
};
var $author$project$Anim$Internal$Builder$getTranslateCssUnitAxes = F2(
	function (animGroupName, builder) {
		var data = builder;
		return A2(
			$author$project$Anim$Internal$Unit$mergeBaselineUnits,
			$elm$core$Maybe$Just(
				$author$project$Anim$Internal$Builder$getScopedDefaults(builder).i),
			A3(
				$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
				animGroupName,
				{ar: $author$project$Anim$Internal$Builder$CssUnitStore$translateX, as: $author$project$Anim$Internal$Builder$CssUnitStore$translateY, at: $author$project$Anim$Internal$Builder$CssUnitStore$translateZ},
				data.a.aX));
	});
var $author$project$Anim$Internal$Builder$getTranslateInitCssUnitAxes = F2(
	function (group, _v0) {
		var data = _v0;
		return A3(
			$author$project$Anim$Internal$Builder$CssUnitStore$getAxes,
			group,
			{ar: $author$project$Anim$Internal$Builder$CssUnitStore$translateX, as: $author$project$Anim$Internal$Builder$CssUnitStore$translateY, at: $author$project$Anim$Internal$Builder$CssUnitStore$translateZ},
			data.c.ab);
	});
var $author$project$Anim$Internal$Builder$setTranslateCurrentGroup = F2(
	function (name, _v0) {
		var data = _v0;
		var defs = data.c;
		return _Utils_update(
			data,
			{
				c: _Utils_update(
					defs,
					{
						aA: $elm$core$Maybe$Just(name)
					})
			});
	});
var $author$project$Anim$Internal$Builder$Translate$for = F2(
	function (animGroupName, builder) {
		var storeUnits = A2($author$project$Anim$Internal$Builder$getTranslateInitCssUnitAxes, animGroupName, builder);
		var scopedGlobalUnits = A2($author$project$Anim$Internal$Builder$getTranslateCssUnitAxes, animGroupName, builder);
		var extractExisting = function (propertyConfig) {
			if (propertyConfig.$ === 8) {
				var cfg = propertyConfig.a;
				return $elm$core$Maybe$Just(cfg);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		};
		var baselineUnits = A2(
			$elm$core$Maybe$andThen,
			$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslateConfiguredUnits,
			A2($author$project$Anim$Internal$Builder$getBaseline, animGroupName, builder));
		var baseConfig = A6($author$project$Anim$Internal$Builder$Property$for, animGroupName, 'translate', $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate, extractExisting, $author$project$Anim$Internal$Builder$Translate$defaultConfig, builder);
		var config = _Utils_update(
			baseConfig,
			{
				E: A2(
					$author$project$Anim$Internal$Unit$mergeBaselineUnits,
					$elm$core$Maybe$Just(storeUnits),
					A2(
						$author$project$Anim$Internal$Unit$mergeBaselineUnits,
						baselineUnits,
						A2(
							$author$project$Anim$Internal$Unit$mergeBaselineUnits,
							$elm$core$Maybe$Just(scopedGlobalUnits),
							baseConfig.E)))
			});
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			config,
			A2(
				$author$project$Anim$Internal$Builder$setTranslateCurrentGroup,
				animGroupName,
				A2($author$project$Anim$Internal$Builder$for, animGroupName, builder)));
	});
var $author$project$Anim$Internal$Builder$Translate$default = 0.0;
var $author$project$Anim$Internal$Builder$Translate$from = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			_Utils_update(
				config,
				{
					bz: $elm$core$Maybe$Just(value)
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Translate$fromXYZ = F3(
	function (x, y, z) {
		return $author$project$Anim$Internal$Builder$Translate$from(
			$author$project$Anim$Internal$Property$Translate$fromTriple(
				_Utils_Tuple3(x, y, z)));
	});
var $author$project$Anim$Internal$Builder$Property$getFloat = F2(
	function (getAxis, _default) {
		return A2(
			$elm$core$Basics$composeR,
			$elm$core$Maybe$map(getAxis),
			$elm$core$Maybe$withDefault(_default));
	});
var $author$project$Anim$Internal$Builder$Translate$fromY = F2(
	function (y, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = A3($author$project$Anim$Internal$Builder$Property$getFloat, $author$project$Anim$Internal$Property$Translate$getZ, $author$project$Anim$Internal$Builder$Translate$default, config.bz);
		var x = A3($author$project$Anim$Internal$Builder$Property$getFloat, $author$project$Anim$Internal$Property$Translate$getX, $author$project$Anim$Internal$Builder$Translate$default, config.bz);
		return A4(
			$author$project$Anim$Internal$Builder$Translate$fromXYZ,
			x,
			y,
			z,
			A2($author$project$Anim$Internal$Builder$Translate$TranslateBuilder, config, builder));
	});
var $author$project$Anim$Property$Translate$fromY = $author$project$Anim$Internal$Builder$Translate$fromY;
var $elm$core$Set$insert = F2(
	function (key, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, key, 0, dict);
	});
var $author$project$Anim$Internal$Builder$markInitTouched = F3(
	function (maybeGroup, slots, _v0) {
		var data = _v0;
		if (maybeGroup.$ === 1) {
			return data;
		} else {
			var group = maybeGroup.a;
			var defs = data.c;
			var touched = A3(
				$elm$core$List$foldl,
				function (s) {
					return $elm$core$Set$insert(
						_Utils_Tuple2(group, s));
				},
				defs.ch,
				slots);
			return _Utils_update(
				data,
				{
					c: _Utils_update(
						defs,
						{ch: touched})
				});
		}
	});
var $author$project$Anim$Internal$Builder$registerTranslateInitAxes = F2(
	function (slots, builder) {
		var data = builder;
		return A3($author$project$Anim$Internal$Builder$markInitTouched, data.c.aA, slots, builder);
	});
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
			anim.bE);
		return _Utils_update(
			data,
			{
				a: _Utils_update(
					anim,
					{bE: newTouchedAxes})
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
var $author$project$Anim$Internal$Builder$Translate$markAxes = F2(
	function (axes, builder) {
		return A3($author$project$Anim$Internal$Builder$markAxes, 'translate', axes, builder);
	});
var $author$project$Anim$Internal$Builder$Property$setEnd = F4(
	function (default_, distanceFn, newEnd, config) {
		var startVal = A2($elm$core$Maybe$withDefault, default_, config.bz);
		return _Utils_update(
			config,
			{
				ct: A2(distanceFn, startVal, newEnd),
				n: newEnd,
				bz: $elm$core$Maybe$Just(startVal)
			});
	});
var $author$project$Anim$Internal$Builder$Translate$setEnd = F2(
	function (newEnd, config) {
		return A4($author$project$Anim$Internal$Builder$Property$setEnd, $author$project$Anim$Internal$Property$Translate$default, $author$project$Anim$Internal$Property$Translate$distance, newEnd, config);
	});
var $author$project$Anim$Internal$Builder$Translate$toY = F2(
	function (y, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = $author$project$Anim$Internal$Property$Translate$getZ(config.n);
		var x = $author$project$Anim$Internal$Property$Translate$getX(config.n);
		var newEnd = $author$project$Anim$Internal$Property$Translate$fromTriple(
			_Utils_Tuple3(x, y, z));
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			A2($author$project$Anim$Internal$Builder$Translate$setEnd, newEnd, config),
			A2(
				$author$project$Anim$Internal$Builder$Translate$markAxes,
				_List_fromArray(
					['y']),
				builder));
	});
var $author$project$Anim$Property$Translate$initY = F3(
	function (animationKey, y, animBuilder) {
		return A2(
			$author$project$Anim$Internal$Builder$registerTranslateInitAxes,
			_List_fromArray(
				[$author$project$Anim$Internal$Builder$CssUnitStore$translateY]),
			$author$project$Anim$Internal$Builder$Translate$build(
				A2(
					$author$project$Anim$Internal$Builder$Translate$toY,
					y,
					A2(
						$author$project$Anim$Property$Translate$fromY,
						y,
						A2($author$project$Anim$Internal$Builder$Translate$for, animationKey, animBuilder)))));
	});
var $author$project$Animation$WAAPI$ControllingAnimations$Main$motionCmd = _Platform_outgoingPort('motionCmd', $elm$core$Basics$identity);
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$motionMsg = _Platform_incomingPort('motionMsg', $elm$json$Json$Decode$value);
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Animation$WAAPI$ControllingAnimations$Main$init = function () {
	var animState = A3(
		$author$project$Anim$Engine$WAAPI$init,
		$author$project$Animation$WAAPI$ControllingAnimations$Main$motionCmd,
		$author$project$Animation$WAAPI$ControllingAnimations$Main$motionMsg,
		_List_fromArray(
			[
				A2(
				$elm$core$Basics$composeR,
				A2($author$project$Anim$Property$Translate$initY, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, 0),
				$author$project$Anim$Property$Translate$initCssUnitY(4))
			]));
	return _Utils_Tuple2(
		{D: animState},
		$elm$core$Platform$Cmd$none);
}();
var $author$project$Animation$WAAPI$ControllingAnimations$Main$GotWaapiMsg = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$JavascriptUpdate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$WAAPI$subscriptions = F2(
	function (toMsg, _v0) {
		var state = _v0.a;
		return state.cJ(
			A2($elm$core$Basics$composeL, toMsg, $elm$core$Basics$identity));
	});
var $author$project$Anim$Engine$WAAPI$subscriptions = $author$project$Anim$Internal$Engine$WAAPI$subscriptions;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$subscriptions = function (model) {
	return A2($author$project$Anim$Engine$WAAPI$subscriptions, $author$project$Animation$WAAPI$ControllingAnimations$Main$GotWaapiMsg, model.D);
};
var $author$project$Anim$Internal$Builder$Snap = {$: 1};
var $author$project$Anim$Internal$Builder$AnimateKind = 0;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl = F3(
	function (f, acc, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$foldl, f, acc, dict);
	});
var $author$project$Anim$Internal$Builder$addToHistoryWithKind = F3(
	function (kind, processedData, _v0) {
		var data = _v0;
		return A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
			F3(
				function (animGroupName, groupConfig, _v1) {
					var accData = _v1;
					var state = accData.x;
					var newEntry = {I: groupConfig, cA: kind};
					var existingHistory = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, state.aC);
					var updatedHistory = function () {
						if (existingHistory.$ === 1) {
							return {aG: newEntry, bi: _List_Nil};
						} else {
							var existing = existingHistory.a;
							return {
								aG: newEntry,
								bi: A2($elm$core$List$cons, existing.aG, existing.bi)
							};
						}
					}();
					return _Utils_update(
						accData,
						{
							x: _Utils_update(
								state,
								{
									aC: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, updatedHistory, state.aC)
								})
						});
				}),
			data,
			processedData.cw);
	});
var $author$project$Anim$Internal$Builder$addAnimationToHistory = $author$project$Anim$Internal$Builder$addToHistoryWithKind(0);
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$union = F2(
	function (_v0, _v1) {
		var a = _v0;
		var b = _v1;
		return A2($elm$core$Dict$union, a, b);
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$addPropertyStates = F2(
	function (_v0, _v1) {
		var newGroup = _v0;
		var existingGroup = _v1;
		return _Utils_update(
			newGroup,
			{
				al: A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$union, newGroup.al, existingGroup.al)
			});
	});
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimationDirection = function (direction) {
	if (!direction) {
		return $elm$json$Json$Encode$string('normal');
	} else {
		return $elm$json$Json$Encode$string('alternate');
	}
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeIterations = function (iterations_) {
	switch (iterations_.$) {
		case 0:
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('once')),
						_Utils_Tuple2(
						'count',
						$elm$json$Json$Encode$int(1))
					]));
		case 1:
			var n = iterations_.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('times')),
						_Utils_Tuple2(
						'count',
						$elm$json$Json$Encode$int(n))
					]));
		default:
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('infinite')),
						_Utils_Tuple2(
						'count',
						$elm$json$Json$Encode$int(-1))
					]));
	}
};
var $elm$json$Json$Encode$bool = _Json_wrap;
var $elm$core$Dict$isEmpty = function (dict) {
	if (dict.$ === -2) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeDiscreteEntryFields = function (dict) {
	return $elm$core$Dict$isEmpty(dict) ? _List_Nil : _List_fromArray(
		[
			_Utils_Tuple2(
			'discreteEntry',
			$elm$json$Json$Encode$object(
				A2(
					$elm$core$List$map,
					function (_v0) {
						var k = _v0.a;
						var v = _v0.b;
						return _Utils_Tuple2(
							k,
							$elm$json$Json$Encode$string(v));
					},
					$elm$core$Dict$toList(dict))))
		]);
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeDiscreteExitFields = function (dict) {
	return $elm$core$Dict$isEmpty(dict) ? _List_Nil : _List_fromArray(
		[
			_Utils_Tuple2(
			'discreteExit',
			$elm$json$Json$Encode$object(
				A2(
					$elm$core$List$map,
					function (_v0) {
						var k = _v0.a;
						var to = _v0.b.cg;
						var from = _v0.b.bX;
						return _Utils_Tuple2(
							k,
							$elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'from',
										$elm$json$Json$Encode$string(from)),
										_Utils_Tuple2(
										'to',
										$elm$json$Json$Encode$string(to))
									])));
					},
					$elm$core$Dict$toList(dict))))
		]);
};
var $elm$json$Json$Encode$float = _Json_wrap;
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeKeyframeSamples = function (samples) {
	return A2(
		$elm$json$Json$Encode$list,
		function (sample) {
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'offset',
						$elm$json$Json$Encode$float(sample.di)),
						_Utils_Tuple2(
						'value',
						$elm$json$Json$Encode$float(sample.dJ))
					]));
		},
		samples);
};
var $author$project$Shared$Easing$Keyframes$bounceOutBoundaryTimes = function () {
	var d1 = 2.75;
	return _List_fromArray(
		[0, 1 / d1, 2 / d1, 2.5 / d1, 1]);
}();
var $author$project$Shared$Easing$Keyframes$bounceOutExtremaTimes = function () {
	var d1 = 2.75;
	return _List_fromArray(
		[1.5 / d1, 2.25 / d1, 2.625 / d1]);
}();
var $author$project$Shared$Easing$Keyframes$bounceOutCriticalTimes = _Utils_ap($author$project$Shared$Easing$Keyframes$bounceOutBoundaryTimes, $author$project$Shared$Easing$Keyframes$bounceOutExtremaTimes);
var $author$project$Shared$Easing$Keyframes$bounceInCriticalTimes = A2(
	$elm$core$List$map,
	function (t) {
		return 1 - t;
	},
	$author$project$Shared$Easing$Keyframes$bounceOutCriticalTimes);
var $author$project$Shared$Easing$Keyframes$bounceInOutCriticalTimes = function () {
	var secondHalf = A2(
		$elm$core$List$map,
		function (t) {
			return 0.5 + (t / 2);
		},
		$author$project$Shared$Easing$Keyframes$bounceOutCriticalTimes);
	var firstHalf = A2(
		$elm$core$List$map,
		function (t) {
			return t / 2;
		},
		$author$project$Shared$Easing$Keyframes$bounceInCriticalTimes);
	return _Utils_ap(firstHalf, secondHalf);
}();
var $author$project$Shared$Easing$Keyframes$defaultKeyframeCount = 60;
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
var $elm$core$Basics$pi = _Basics_pi;
var $elm$core$Basics$pow = _Basics_pow;
var $elm$core$Basics$sin = _Basics_sin;
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
var $elm_community$easing_functions$Ease$inOut = F3(
	function (e1, e2, time) {
		return (time < 0.5) ? (e1(time * 2) / 2) : (0.5 + (e2((time - 0.5) * 2) / 2));
	});
var $elm_community$easing_functions$Ease$inOutBounce = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBounce, $elm_community$easing_functions$Ease$outBounce);
var $elm_community$easing_functions$Ease$outElastic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inElastic);
var $elm_community$easing_functions$Ease$inOutElastic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inElastic, $elm_community$easing_functions$Ease$outElastic);
var $author$project$Shared$Easing$Keyframes$dedupeSorted = F2(
	function (epsilon, sortedTimes) {
		return $elm$core$List$reverse(
			A3(
				$elm$core$List$foldl,
				F2(
					function (time, acc) {
						if (acc.b) {
							var previous = acc.a;
							return (_Utils_cmp(
								$elm$core$Basics$abs(time - previous),
								epsilon) < 1) ? acc : A2($elm$core$List$cons, time, acc);
						} else {
							return _List_fromArray(
								[time]);
						}
					}),
				_List_Nil,
				sortedTimes));
	});
var $elm$core$List$sortBy = _List_sortBy;
var $elm$core$List$sort = function (xs) {
	return A2($elm$core$List$sortBy, $elm$core$Basics$identity, xs);
};
var $author$project$Shared$Easing$Keyframes$normalizeTimes = function (times) {
	return A2(
		$author$project$Shared$Easing$Keyframes$dedupeSorted,
		0.0000001,
		$elm$core$List$sort(
			A2(
				$elm$core$List$map,
				A2($elm$core$Basics$clamp, 0, 1),
				times)));
};
var $author$project$Shared$Easing$Keyframes$uniformTimes = function (n) {
	return (n <= 1) ? ((n === 1) ? _List_fromArray(
		[0]) : _List_Nil) : A2(
		$elm$core$List$map,
		function (t) {
			return t / (n - 1);
		},
		A2($elm$core$List$range, 0, n - 1));
};
var $author$project$Shared$Easing$Keyframes$mergeSampleTimes = F2(
	function (n, criticalTimes) {
		return $author$project$Shared$Easing$Keyframes$normalizeTimes(
			_Utils_ap(
				$author$project$Shared$Easing$Keyframes$uniformTimes(n),
				criticalTimes));
	});
var $author$project$Shared$Easing$Keyframes$sampleWithCriticalPoints = F3(
	function (f, n, criticalTimes) {
		return A2(
			$elm$core$List$map,
			function (t) {
				return {
					di: t,
					dJ: f(t)
				};
			},
			A2($author$project$Shared$Easing$Keyframes$mergeSampleTimes, n, criticalTimes));
	});
var $author$project$Shared$Easing$Keyframes$uniformSamples = F2(
	function (f, n) {
		return (n <= 1) ? ((n === 1) ? _List_fromArray(
			[
				{
				di: 0,
				dJ: f(0)
			}
			]) : _List_Nil) : A2(
			$elm$core$List$map,
			function (i) {
				var t = i / (n - 1);
				return {
					di: t,
					dJ: f(t)
				};
			},
			A2($elm$core$List$range, 0, n - 1));
	});
var $author$project$Shared$Easing$Keyframes$generateKeyframes = F2(
	function (easing, _v0) {
		switch (easing.$) {
			case 3:
				return A3($author$project$Shared$Easing$Keyframes$sampleWithCriticalPoints, $elm_community$easing_functions$Ease$inBounce, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount, $author$project$Shared$Easing$Keyframes$bounceInCriticalTimes);
			case 4:
				return A3($author$project$Shared$Easing$Keyframes$sampleWithCriticalPoints, $elm_community$easing_functions$Ease$outBounce, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount, $author$project$Shared$Easing$Keyframes$bounceOutCriticalTimes);
			case 5:
				return A3($author$project$Shared$Easing$Keyframes$sampleWithCriticalPoints, $elm_community$easing_functions$Ease$inOutBounce, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount, $author$project$Shared$Easing$Keyframes$bounceInOutCriticalTimes);
			case 17:
				return A2($author$project$Shared$Easing$Keyframes$uniformSamples, $elm_community$easing_functions$Ease$inElastic, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount);
			case 18:
				return A2($author$project$Shared$Easing$Keyframes$uniformSamples, $elm_community$easing_functions$Ease$outElastic, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount);
			case 19:
				return A2($author$project$Shared$Easing$Keyframes$uniformSamples, $elm_community$easing_functions$Ease$inOutElastic, $author$project$Shared$Easing$Keyframes$defaultKeyframeCount);
			default:
				return _List_fromArray(
					[
						{di: 0.0, dJ: 0.0},
						{di: 1.0, dJ: 1.0}
					]);
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$isComplexEasing = function (easing_) {
	switch (easing_.$) {
		case 17:
			return true;
		case 18:
			return true;
		case 19:
			return true;
		case 3:
			return true;
		case 4:
			return true;
		case 5:
			return true;
		case 0:
			return true;
		case 1:
			return true;
		case 2:
			return true;
		default:
			return false;
	}
};
var $author$project$Shared$Easing$Keyframes$sampleCountForDuration = function (durationMs) {
	var target = $elm$core$Basics$round(durationMs / 16.0);
	return A2(
		$elm$core$Basics$max,
		$author$project$Shared$Easing$Keyframes$defaultKeyframeCount,
		A2($elm$core$Basics$min, 1000, target));
};
var $elm$core$Basics$cos = _Basics_cos;
var $author$project$Shared$Spring$displacement = F2(
	function (sol, t) {
		switch (sol.$) {
			case 0:
				var b = sol.a.cR;
				var a = sol.a.cN;
				var zeta = sol.a.bJ;
				var omegaD = sol.a.b1;
				var omega0 = sol.a.aj;
				return A2($elm$core$Basics$pow, $elm$core$Basics$e, ((-zeta) * omega0) * t) * ((a * $elm$core$Basics$cos(omegaD * t)) + (b * $elm$core$Basics$sin(omegaD * t)));
			case 1:
				var b = sol.a.cR;
				var a = sol.a.cN;
				var omega0 = sol.a.aj;
				return (a + (b * t)) * A2($elm$core$Basics$pow, $elm$core$Basics$e, (-omega0) * t);
			default:
				var b = sol.a.cR;
				var a = sol.a.cN;
				var r2 = sol.a.bx;
				var r1 = sol.a.bw;
				return (a * A2($elm$core$Basics$pow, $elm$core$Basics$e, r1 * t)) + (b * A2($elm$core$Basics$pow, $elm$core$Basics$e, r2 * t));
		}
	});
var $author$project$Shared$Spring$valueAt = F2(
	function (params, timeMs) {
		return params.cg + A2(
			$author$project$Shared$Spring$displacement,
			$author$project$Shared$Spring$precompute(params),
			timeMs / 1000.0);
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$springKeyframes = F2(
	function (s, durationMs) {
		var n = $author$project$Shared$Easing$Keyframes$sampleCountForDuration(durationMs);
		var motion = {
			bX: 0,
			by: $author$project$Motion$Internal$Spring$unwrap(s),
			cg: 1
		};
		return A2(
			$elm$core$List$map,
			function (i) {
				var offset = i / (n - 1);
				return {
					di: offset,
					dJ: A2($author$project$Shared$Spring$valueAt, motion, offset * durationMs)
				};
			},
			A2($elm$core$List$range, 0, n - 1));
	});
var $elm$core$String$fromFloat = _String_fromNumber;
var $author$project$Shared$Easing$toWebAnimations = function (easing) {
	switch (easing.$) {
		case 9:
			var p1x = easing.a;
			var p1y = easing.b;
			var p2x = easing.c;
			var p2y = easing.d;
			return 'cubic-bezier(' + ($elm$core$String$fromFloat(p1x) + (', ' + ($elm$core$String$fromFloat(p1y) + (', ' + ($elm$core$String$fromFloat(p2x) + (', ' + ($elm$core$String$fromFloat(p2y) + ')')))))));
		case 23:
			return 'linear';
		case 13:
			return 'ease';
		case 14:
			return 'ease-in';
		case 15:
			return 'ease-out';
		case 16:
			return 'ease-in-out';
		case 33:
			return 'cubic-bezier(0.12, 0, 0.39, 0)';
		case 34:
			return 'cubic-bezier(0.61, 1, 0.88, 1)';
		case 35:
			return 'cubic-bezier(0.37, 0, 0.63, 1)';
		case 24:
			return 'cubic-bezier(0.11, 0, 0.5, 0)';
		case 25:
			return 'cubic-bezier(0.5, 1, 0.89, 1)';
		case 26:
			return 'cubic-bezier(0.45, 0, 0.55, 1)';
		case 10:
			return 'cubic-bezier(0.32, 0, 0.67, 0)';
		case 11:
			return 'cubic-bezier(0.67, 0, 0.32, 1)';
		case 12:
			return 'cubic-bezier(0.65, 0, 0.35, 1)';
		case 27:
			return 'cubic-bezier(0.5, 0, 0.75, 0)';
		case 28:
			return 'cubic-bezier(0.25, 1, 0.5, 1)';
		case 29:
			return 'cubic-bezier(0.76, 0, 0.24, 1)';
		case 30:
			return 'cubic-bezier(0.64, 0, 0.78, 0)';
		case 31:
			return 'cubic-bezier(0.22, 1, 0.36, 1)';
		case 32:
			return 'cubic-bezier(0.83, 0, 0.17, 1)';
		case 20:
			return 'cubic-bezier(0.7, 0, 0.84, 0)';
		case 21:
			return 'cubic-bezier(0.16, 1, 0.3, 1)';
		case 22:
			return 'cubic-bezier(0.87, 0, 0.13, 1)';
		case 6:
			return 'cubic-bezier(0.55, 0, 1, 0.45)';
		case 7:
			return 'cubic-bezier(0, 0.55, 0.45, 1)';
		case 8:
			return 'cubic-bezier(0.85, 0, 0.15, 1)';
		case 0:
			return 'cubic-bezier(0.36, 0, 0.66, -0.56)';
		case 1:
			return 'cubic-bezier(0.34, 1.56, 0.64, 1)';
		case 2:
			return 'cubic-bezier(0.68, -0.6, 0.32, 1.6)';
		case 17:
			return 'linear';
		case 18:
			return 'linear';
		case 19:
			return 'linear';
		case 3:
			return 'linear';
		case 4:
			return 'linear';
		default:
			return 'linear';
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes = F3(
	function (durationMs, easingValue, maybeSpring) {
		if (!maybeSpring.$) {
			var s = maybeSpring.a;
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'easing',
					$elm$json$Json$Encode$string('linear')),
					_Utils_Tuple2(
					'easingKeyframes',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeKeyframeSamples(
						A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$springKeyframes, s, durationMs)))
				]);
		} else {
			return $author$project$Anim$Internal$Engine$WAAPI$Encoder$isComplexEasing(easingValue) ? _List_fromArray(
				[
					_Utils_Tuple2(
					'easing',
					$elm$json$Json$Encode$string('linear')),
					_Utils_Tuple2(
					'easingKeyframes',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeKeyframeSamples(
						A2($author$project$Shared$Easing$Keyframes$generateKeyframes, easingValue, durationMs)))
				]) : _List_fromArray(
				[
					_Utils_Tuple2(
					'easing',
					$elm$json$Json$Encode$string(
						$author$project$Shared$Easing$toWebAnimations(easingValue)))
				]);
		}
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
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyTypeString = function (property) {
	switch (property.$) {
		case 8:
			return 'translate';
		case 4:
			return 'rotate';
		case 7:
			return 'skew';
		case 5:
			return 'scale';
		case 2:
			return 'opacity';
		case 3:
			return 'perspectiveOrigin';
		case 6:
			return 'size';
		case 0:
			var cssName = property.a;
			return 'custom:' + cssName;
		default:
			var cssName = property.a;
			return 'customColor:' + cssName;
	}
};
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
			var b = color.a.cR;
			var g = color.a.c1;
			var r = color.a.dy;
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
			var a = color.a.cN;
			var b = color.a.cR;
			var g = color.a.c1;
			var r = color.a.dy;
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
			var l = color.a.dc;
			var s = color.a.dB;
			var h = color.a.c2;
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
			var a = color.a.cN;
			var l = color.a.dc;
			var s = color.a.dB;
			var h = color.a.c2;
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
var $author$project$Anim$Internal$Property$Opacity$toFloat = function (_v0) {
	var o = _v0;
	return o;
};
var $author$project$Anim$Internal$Property$Shared$Axis3$toTriple = F2(
	function (support, coord) {
		var record = support.f5(coord);
		return _Utils_Tuple3(record.ar, record.as, record.at);
	});
var $author$project$Anim$Internal$Property$Rotate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Property$Scale$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Translate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Property$Size$toTuple = function (_v0) {
	var dimensions = _v0;
	return _Utils_Tuple2(dimensions.R, dimensions.c2);
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeProcessedPropertyConfig = F4(
	function (maybeVersions, frozenAxes, touchedAxes, property) {
		var versionFields = function () {
			if (!maybeVersions.$) {
				var propertyVersions = maybeVersions.a;
				var propType = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyTypeString(property);
				var version = A2(
					$elm$core$Maybe$withDefault,
					1,
					A2(
						$elm$core$Maybe$map,
						function ($) {
							return $.bH;
						},
						A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, propertyVersions)));
				return _List_fromArray(
					[
						_Utils_Tuple2(
						'version',
						$elm$json$Json$Encode$int(version))
					]);
			} else {
				return _List_Nil;
			}
		}();
		var touchedAxesFields = F2(
			function (propName, axisNames) {
				var _v18 = A2($elm$core$Dict$get, propName, touchedAxes);
				if (_v18.$ === 1) {
					return _List_Nil;
				} else {
					var axisSet = _v18.a;
					return A2(
						$elm$core$List$map,
						function (_v19) {
							var axis = _v19.a;
							var field = _v19.b;
							return _Utils_Tuple2(
								field,
								$elm$json$Json$Encode$bool(
									A2($elm$core$Set$member, axis, axisSet)));
						},
						axisNames);
				}
			});
		var frozenAxesField = function (propName) {
			var _v17 = A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2($elm$core$Dict$get, propName, frozenAxes));
			if (!_v17.b) {
				return _List_Nil;
			} else {
				var axes = _v17;
				return _List_fromArray(
					[
						_Utils_Tuple2(
						'frozenAxes',
						A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, axes))
					]);
			}
		};
		var encodeTripleStart = F3(
			function (toTriple, _default, maybeStart) {
				if (!maybeVersions.$) {
					if (!maybeStart.$) {
						var start = maybeStart.a;
						var _v15 = toTriple(start);
						var sx = _v15.a;
						var sy = _v15.b;
						var sz = _v15.c;
						return _List_fromArray(
							[
								_Utils_Tuple2(
								'startX',
								$elm$json$Json$Encode$float(sx)),
								_Utils_Tuple2(
								'startY',
								$elm$json$Json$Encode$float(sy)),
								_Utils_Tuple2(
								'startZ',
								$elm$json$Json$Encode$float(sz))
							]);
					} else {
						return _List_fromArray(
							[
								_Utils_Tuple2('startX', $elm$json$Json$Encode$null),
								_Utils_Tuple2('startY', $elm$json$Json$Encode$null),
								_Utils_Tuple2('startZ', $elm$json$Json$Encode$null)
							]);
					}
				} else {
					var _v16 = A2(
						$elm$core$Maybe$withDefault,
						_default,
						A2($elm$core$Maybe$map, toTriple, maybeStart));
					var sx = _v16.a;
					var sy = _v16.b;
					var sz = _v16.c;
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'startX',
							$elm$json$Json$Encode$float(sx)),
							_Utils_Tuple2(
							'startY',
							$elm$json$Json$Encode$float(sy)),
							_Utils_Tuple2(
							'startZ',
							$elm$json$Json$Encode$float(sz))
						]);
				}
			});
		switch (property.$) {
			case 0:
				var cssName = property.a;
				var unit = property.b;
				var config = property.c;
				var startValue = A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					A2(
						$elm$core$Maybe$map,
						function (s) {
							return _List_fromArray(
								[
									_Utils_Tuple2(
									'startValue',
									$elm$json$Json$Encode$float(s))
								]);
						},
						config.bz));
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('customProperty')),
						A2(
							$elm$core$List$cons,
							_Utils_Tuple2(
								'cssProperty',
								$elm$json$Json$Encode$string(cssName)),
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									'unit',
									$elm$json$Json$Encode$string(unit)),
								_Utils_ap(
									versionFields,
									_Utils_ap(
										_List_fromArray(
											[
												_Utils_Tuple2(
												'endValue',
												$elm$json$Json$Encode$float(config.n)),
												_Utils_Tuple2(
												'duration',
												$elm$json$Json$Encode$int(config.y)),
												_Utils_Tuple2(
												'delay',
												$elm$json$Json$Encode$int(config.v))
											]),
										_Utils_ap(
											startValue,
											A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))))));
			case 1:
				var cssName = property.a;
				var config = property.b;
				var startColorField = A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					A2(
						$elm$core$Maybe$map,
						function (start) {
							return _List_fromArray(
								[
									_Utils_Tuple2(
									'startColor',
									$elm$json$Json$Encode$string(
										$author$project$Anim$Internal$Extra$Color$toCssString(start)))
								]);
						},
						config.bz));
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('customColorProperty')),
						A2(
							$elm$core$List$cons,
							_Utils_Tuple2(
								'cssProperty',
								$elm$json$Json$Encode$string(cssName)),
							_Utils_ap(
								versionFields,
								_Utils_ap(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'endColor',
											$elm$json$Json$Encode$string(
												$author$project$Anim$Internal$Extra$Color$toCssString(config.n))),
											_Utils_Tuple2(
											'duration',
											$elm$json$Json$Encode$int(config.y)),
											_Utils_Tuple2(
											'delay',
											$elm$json$Json$Encode$int(config.v))
										]),
									_Utils_ap(
										startColorField,
										A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by)))))));
			case 2:
				var config = property.a;
				var startValue = A2(
					$elm$core$Maybe$withDefault,
					1.0,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Property$Opacity$toFloat, config.bz));
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('opacity')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'startValue',
										$elm$json$Json$Encode$float(startValue)),
										_Utils_Tuple2(
										'endValue',
										$elm$json$Json$Encode$float(
											$author$project$Anim$Internal$Property$Opacity$toFloat(config.n))),
										_Utils_Tuple2(
										'duration',
										$elm$json$Json$Encode$int(config.y)),
										_Utils_Tuple2(
										'delay',
										$elm$json$Json$Encode$int(config.v))
									]),
								A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by)))));
			case 3:
				var config = property.a;
				var _v1 = A2(
					$elm$core$Maybe$withDefault,
					_Utils_Tuple2(50, 50),
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple, config.bz));
				var startX = _v1.a;
				var startY = _v1.b;
				var _v2 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(config.n);
				var endX = _v2.a;
				var endY = _v2.b;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('perspectiveOrigin')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'startX',
										$elm$json$Json$Encode$float(startX)),
										_Utils_Tuple2(
										'startY',
										$elm$json$Json$Encode$float(startY)),
										_Utils_Tuple2(
										'endX',
										$elm$json$Json$Encode$float(endX)),
										_Utils_Tuple2(
										'endY',
										$elm$json$Json$Encode$float(endY)),
										_Utils_Tuple2(
										'unitX',
										$elm$json$Json$Encode$string(
											$author$project$Anim$Internal$Unit$toCssSuffix(config.E.ar))),
										_Utils_Tuple2(
										'unitY',
										$elm$json$Json$Encode$string(
											$author$project$Anim$Internal$Unit$toCssSuffix(config.E.as))),
										_Utils_Tuple2(
										'duration',
										$elm$json$Json$Encode$int(config.y)),
										_Utils_Tuple2(
										'delay',
										$elm$json$Json$Encode$int(config.v))
									]),
								_Utils_ap(
									A2(
										touchedAxesFields,
										'perspectiveOrigin',
										_List_fromArray(
											[
												_Utils_Tuple2('x', 'touchedX'),
												_Utils_Tuple2('y', 'touchedY')
											])),
									A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))));
			case 5:
				var config = property.a;
				var _v3 = $author$project$Anim$Internal$Property$Scale$toTriple(config.n);
				var endX = _v3.a;
				var endY = _v3.b;
				var endZ = _v3.c;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('scale')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								A3(
									encodeTripleStart,
									$author$project$Anim$Internal$Property$Scale$toTriple,
									_Utils_Tuple3(1, 1, 1),
									config.bz),
								_Utils_ap(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'endX',
											$elm$json$Json$Encode$float(endX)),
											_Utils_Tuple2(
											'endY',
											$elm$json$Json$Encode$float(endY)),
											_Utils_Tuple2(
											'endZ',
											$elm$json$Json$Encode$float(endZ)),
											_Utils_Tuple2(
											'duration',
											$elm$json$Json$Encode$int(config.y)),
											_Utils_Tuple2(
											'delay',
											$elm$json$Json$Encode$int(config.v))
										]),
									_Utils_ap(
										frozenAxesField('scale'),
										_Utils_ap(
											A2(
												touchedAxesFields,
												'scale',
												_List_fromArray(
													[
														_Utils_Tuple2('x', 'touchedX'),
														_Utils_Tuple2('y', 'touchedY'),
														_Utils_Tuple2('z', 'touchedZ')
													])),
											A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))))));
			case 4:
				var config = property.a;
				var _v4 = $author$project$Anim$Internal$Property$Rotate$toTriple(config.n);
				var endX = _v4.a;
				var endY = _v4.b;
				var endZ = _v4.c;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('rotate')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								A3(
									encodeTripleStart,
									$author$project$Anim$Internal$Property$Rotate$toTriple,
									_Utils_Tuple3(0, 0, 0),
									config.bz),
								_Utils_ap(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'endX',
											$elm$json$Json$Encode$float(endX)),
											_Utils_Tuple2(
											'endY',
											$elm$json$Json$Encode$float(endY)),
											_Utils_Tuple2(
											'endZ',
											$elm$json$Json$Encode$float(endZ)),
											_Utils_Tuple2(
											'duration',
											$elm$json$Json$Encode$int(config.y)),
											_Utils_Tuple2(
											'delay',
											$elm$json$Json$Encode$int(config.v))
										]),
									_Utils_ap(
										frozenAxesField('rotate'),
										_Utils_ap(
											A2(
												touchedAxesFields,
												'rotate',
												_List_fromArray(
													[
														_Utils_Tuple2('x', 'touchedX'),
														_Utils_Tuple2('y', 'touchedY'),
														_Utils_Tuple2('z', 'touchedZ')
													])),
											A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))))));
			case 7:
				var config = property.a;
				var startFields = function () {
					if (!maybeVersions.$) {
						var _v7 = config.bz;
						if (!_v7.$) {
							var start = _v7.a;
							var _v8 = $author$project$Anim$Internal$Property$Skew$toTuple(start);
							var startX = _v8.a;
							var startY = _v8.b;
							return _List_fromArray(
								[
									_Utils_Tuple2(
									'startX',
									$elm$json$Json$Encode$float(startX)),
									_Utils_Tuple2(
									'startY',
									$elm$json$Json$Encode$float(startY))
								]);
						} else {
							return _List_fromArray(
								[
									_Utils_Tuple2('startX', $elm$json$Json$Encode$null),
									_Utils_Tuple2('startY', $elm$json$Json$Encode$null)
								]);
						}
					} else {
						var _v9 = A2(
							$elm$core$Maybe$withDefault,
							_Utils_Tuple2(0, 0),
							A2($elm$core$Maybe$map, $author$project$Anim$Internal$Property$Skew$toTuple, config.bz));
						var startX = _v9.a;
						var startY = _v9.b;
						return _List_fromArray(
							[
								_Utils_Tuple2(
								'startX',
								$elm$json$Json$Encode$float(startX)),
								_Utils_Tuple2(
								'startY',
								$elm$json$Json$Encode$float(startY))
							]);
					}
				}();
				var _v5 = $author$project$Anim$Internal$Property$Skew$toTuple(config.n);
				var endX = _v5.a;
				var endY = _v5.b;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('skew')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								startFields,
								_Utils_ap(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'endX',
											$elm$json$Json$Encode$float(endX)),
											_Utils_Tuple2(
											'endY',
											$elm$json$Json$Encode$float(endY)),
											_Utils_Tuple2(
											'duration',
											$elm$json$Json$Encode$int(config.y)),
											_Utils_Tuple2(
											'delay',
											$elm$json$Json$Encode$int(config.v))
										]),
									_Utils_ap(
										frozenAxesField('skew'),
										_Utils_ap(
											A2(
												touchedAxesFields,
												'skew',
												_List_fromArray(
													[
														_Utils_Tuple2('x', 'touchedX'),
														_Utils_Tuple2('y', 'touchedY')
													])),
											A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))))));
			case 6:
				var config = property.a;
				var _v10 = A2(
					$elm$core$Maybe$withDefault,
					_Utils_Tuple2(0, 0),
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Property$Size$toTuple, config.bz));
				var startWidth = _v10.a;
				var startHeight = _v10.b;
				var _v11 = $author$project$Anim$Internal$Property$Size$toTuple(config.n);
				var endWidth = _v11.a;
				var endHeight = _v11.b;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('size')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'startWidth',
										$elm$json$Json$Encode$float(startWidth)),
										_Utils_Tuple2(
										'startHeight',
										$elm$json$Json$Encode$float(startHeight)),
										_Utils_Tuple2(
										'endWidth',
										$elm$json$Json$Encode$float(endWidth)),
										_Utils_Tuple2(
										'endHeight',
										$elm$json$Json$Encode$float(endHeight)),
										_Utils_Tuple2(
										'unitWidth',
										$elm$json$Json$Encode$string(
											$author$project$Anim$Internal$Unit$toCssSuffix(config.E.ar))),
										_Utils_Tuple2(
										'unitHeight',
										$elm$json$Json$Encode$string(
											$author$project$Anim$Internal$Unit$toCssSuffix(config.E.as))),
										_Utils_Tuple2(
										'duration',
										$elm$json$Json$Encode$int(config.y)),
										_Utils_Tuple2(
										'delay',
										$elm$json$Json$Encode$int(config.v))
									]),
								_Utils_ap(
									A2(
										touchedAxesFields,
										'size',
										_List_fromArray(
											[
												_Utils_Tuple2('width', 'touchedWidth'),
												_Utils_Tuple2('height', 'touchedHeight')
											])),
									A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))));
			default:
				var config = property.a;
				var _v12 = $author$project$Anim$Internal$Property$Translate$toTriple(config.n);
				var endX = _v12.a;
				var endY = _v12.b;
				var endZ = _v12.c;
				return $elm$json$Json$Encode$object(
					A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('translate')),
						_Utils_ap(
							versionFields,
							_Utils_ap(
								A3(
									encodeTripleStart,
									$author$project$Anim$Internal$Property$Translate$toTriple,
									_Utils_Tuple3(0, 0, 0),
									config.bz),
								_Utils_ap(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'endX',
											$elm$json$Json$Encode$float(endX)),
											_Utils_Tuple2(
											'endY',
											$elm$json$Json$Encode$float(endY)),
											_Utils_Tuple2(
											'endZ',
											$elm$json$Json$Encode$float(endZ)),
											_Utils_Tuple2(
											'unitX',
											$elm$json$Json$Encode$string(
												$author$project$Anim$Internal$Unit$toCssSuffix(config.E.ar))),
											_Utils_Tuple2(
											'unitY',
											$elm$json$Json$Encode$string(
												$author$project$Anim$Internal$Unit$toCssSuffix(config.E.as))),
											_Utils_Tuple2(
											'unitZ',
											$elm$json$Json$Encode$string(
												$author$project$Anim$Internal$Unit$toCssSuffix(config.E.at))),
											_Utils_Tuple2(
											'duration',
											$elm$json$Json$Encode$int(config.y)),
											_Utils_Tuple2(
											'delay',
											$elm$json$Json$Encode$int(config.v))
										]),
									_Utils_ap(
										frozenAxesField('translate'),
										_Utils_ap(
											A2(
												touchedAxesFields,
												'translate',
												_List_fromArray(
													[
														_Utils_Tuple2('x', 'touchedX'),
														_Utils_Tuple2('y', 'touchedY'),
														_Utils_Tuple2('z', 'touchedZ')
													])),
											A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeEasingWithKeyframes, config.y, config.bW, config.by))))))));
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeTransformOrder = function (order) {
	return A2(
		$elm$json$Json$Encode$list,
		function (t) {
			switch (t) {
				case 0:
					return $elm$json$Json$Encode$string('translate');
				case 1:
					return $elm$json$Json$Encode$string('rotate');
				case 2:
					return $elm$json$Json$Encode$string('skew');
				default:
					return $elm$json$Json$Encode$string('scale');
			}
		},
		order);
};
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
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeProcessedAnimGroupConfig = function (animGroupName) {
	return function (targetId) {
		return function (propertyState) {
			return function (transformOrder_) {
				return function (transformBaseline) {
					return function (viewRangeStart) {
						return function (viewRangeEnd) {
							return function (emitProgress_) {
								return function (updateThrottleMs) {
									return function (frozenAxes) {
										return function (discreteEntryProperties) {
											return function (discreteExitProperties) {
												return function (touchedAxes) {
													return function (iterations_) {
														return function (direction_) {
															return function (propertyConfigs) {
																var willChangeField = function () {
																	var _v0 = $author$project$Anim$Internal$Builder$willChangeComposite(propertyConfigs);
																	if (_v0 === '') {
																		return _List_Nil;
																	} else {
																		var value = _v0;
																		return _List_fromArray(
																			[
																				_Utils_Tuple2(
																				'willChange',
																				$elm$json$Json$Encode$string(value))
																			]);
																	}
																}();
																var viewRangeFields = A2(
																	$elm$core$List$filterMap,
																	$elm$core$Basics$identity,
																	_List_fromArray(
																		[
																			A2(
																			$elm$core$Maybe$map,
																			function (range) {
																				return _Utils_Tuple2(
																					'rangeStart',
																					$elm$json$Json$Encode$string(range));
																			},
																			viewRangeStart),
																			A2(
																			$elm$core$Maybe$map,
																			function (range) {
																				return _Utils_Tuple2(
																					'rangeEnd',
																					$elm$json$Json$Encode$string(range));
																			},
																			viewRangeEnd)
																		]));
																var updateThrottleField = (updateThrottleMs > 0) ? _List_fromArray(
																	[
																		_Utils_Tuple2(
																		'throttleIntervalMs',
																		$elm$json$Json$Encode$int(updateThrottleMs))
																	]) : _List_Nil;
																var orderField = A2(
																	$elm$core$Maybe$withDefault,
																	_List_Nil,
																	A2(
																		$elm$core$Maybe$map,
																		function (order) {
																			return _List_fromArray(
																				[
																					_Utils_Tuple2(
																					'transformOrder',
																					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeTransformOrder(order))
																				]);
																		},
																		transformOrder_));
																var emitProgressField = A2(
																	$elm$core$Maybe$withDefault,
																	_List_Nil,
																	A2(
																		$elm$core$Maybe$map,
																		function (enabled) {
																			return _List_fromArray(
																				[
																					_Utils_Tuple2(
																					'emitProgress',
																					$elm$json$Json$Encode$bool(enabled))
																				]);
																		},
																		emitProgress_));
																var discreteExitField = $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeDiscreteExitFields(discreteExitProperties);
																var discreteEntryField = $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeDiscreteEntryFields(discreteEntryProperties);
																var baselineField = A2(
																	$elm$core$Maybe$withDefault,
																	_List_Nil,
																	A2(
																		$elm$core$Maybe$map,
																		function (baseline) {
																			return _List_fromArray(
																				[
																					_Utils_Tuple2('transformBaseline', baseline)
																				]);
																		},
																		transformBaseline));
																var baseFields = _List_fromArray(
																	[
																		_Utils_Tuple2(
																		'properties',
																		A2(
																			$elm$json$Json$Encode$list,
																			A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeProcessedPropertyConfig, propertyState, frozenAxes, touchedAxes),
																			propertyConfigs)),
																		_Utils_Tuple2(
																		'animGroup',
																		$elm$json$Json$Encode$string(animGroupName)),
																		_Utils_Tuple2(
																		'target',
																		$elm$json$Json$Encode$string(targetId)),
																		_Utils_Tuple2(
																		'iterations',
																		$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeIterations(iterations_)),
																		_Utils_Tuple2(
																		'direction',
																		$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimationDirection(direction_))
																	]);
																return $elm$json$Json$Encode$object(
																	_Utils_ap(
																		baseFields,
																		_Utils_ap(
																			orderField,
																			_Utils_ap(
																				baselineField,
																				_Utils_ap(
																					viewRangeFields,
																					_Utils_ap(
																						emitProgressField,
																						_Utils_ap(
																							updateThrottleField,
																							_Utils_ap(
																								discreteEntryField,
																								_Utils_ap(discreteExitField, willChangeField)))))))));
															};
														};
													};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getRotate = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 6) {
				var r = v.a;
				return $elm$core$Maybe$Just(r);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'rotate', dict));
};
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
var $author$project$Anim$Internal$Builder$PropertyBaselines$getSkew = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 11) {
				var s = v.a;
				return $elm$core$Maybe$Just(s);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'skew', dict));
};
var $author$project$Anim$Internal$Property$Rotate$getX = function (_v0) {
	var angles = _v0;
	return angles.ar;
};
var $author$project$Anim$Internal$Property$Scale$getX = function (_v0) {
	var x = _v0.ar;
	return x;
};
var $author$project$Anim$Internal$Property$Skew$getX = function (_v0) {
	var values = _v0;
	return values.ar;
};
var $author$project$Anim$Internal$Property$Rotate$getY = function (_v0) {
	var angles = _v0;
	return angles.as;
};
var $author$project$Anim$Internal$Property$Scale$getY = function (_v0) {
	var y = _v0.as;
	return y;
};
var $author$project$Anim$Internal$Property$Skew$getY = function (_v0) {
	var values = _v0;
	return values.as;
};
var $author$project$Anim$Internal$Property$Rotate$getZ = function (_v0) {
	var angles = _v0;
	return angles.at;
};
var $author$project$Anim$Internal$Property$Scale$getZ = function (_v0) {
	var z = _v0.at;
	return z;
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeTransformBaseline = function (snapshot) {
	var translateField = A2(
		$elm$core$Maybe$map,
		function (t) {
			return _Utils_Tuple2(
				'translate',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Translate$getX(t))),
							_Utils_Tuple2(
							'y',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Translate$getY(t))),
							_Utils_Tuple2(
							'z',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Translate$getZ(t)))
						])));
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate(snapshot));
	var skewField = A2(
		$elm$core$Maybe$map,
		function (sk) {
			return _Utils_Tuple2(
				'skew',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Skew$getX(sk))),
							_Utils_Tuple2(
							'y',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Skew$getY(sk)))
						])));
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$getSkew(snapshot));
	var scaleField = A2(
		$elm$core$Maybe$map,
		function (s) {
			return _Utils_Tuple2(
				'scale',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Scale$getX(s))),
							_Utils_Tuple2(
							'y',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Scale$getY(s))),
							_Utils_Tuple2(
							'z',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Scale$getZ(s)))
						])));
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$getScale(snapshot));
	var rotateField = A2(
		$elm$core$Maybe$map,
		function (r) {
			return _Utils_Tuple2(
				'rotate',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Rotate$getX(r))),
							_Utils_Tuple2(
							'y',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Rotate$getY(r))),
							_Utils_Tuple2(
							'z',
							$elm$json$Json$Encode$float(
								$author$project$Anim$Internal$Property$Rotate$getZ(r)))
						])));
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$getRotate(snapshot));
	var fields = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[translateField, scaleField, rotateField, skewField]));
	return $elm$core$List$isEmpty(fields) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
		$elm$json$Json$Encode$object(fields));
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot = function (_v0) {
	var group = _v0;
	return group.fq;
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates = function (_v0) {
	var group = _v0;
	return group.al;
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getTransformOrder = function (_v0) {
	var group = _v0;
	return group.p;
};
var $author$project$Anim$Internal$Builder$resolvePlayback = F3(
	function (globalIterations, globalDirection, maybePlayback) {
		if (maybePlayback.$ === 1) {
			return {A: globalDirection, t: globalIterations};
		} else {
			var playback = maybePlayback.a;
			return {
				A: A2($elm$core$Maybe$withDefault, globalDirection, playback.A),
				t: A2($elm$core$Maybe$withDefault, globalIterations, playback.t)
			};
		}
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$toList(dict);
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$touchedAxesForGroup = F2(
	function (animGroupName, touchedAxes) {
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (_v0, axisSet, acc) {
					var group = _v0.a;
					var propName = _v0.b;
					return _Utils_eq(group, animGroupName) ? A3($elm$core$Dict$insert, propName, axisSet, acc) : acc;
				}),
			$elm$core$Dict$empty,
			touchedAxes);
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimateLike = F4(
	function (typeTag, animGroups, touchedAxes, processed) {
		var elementsWithVersions = A2(
			$elm$core$List$map,
			function (_v0) {
				var animGroupName = _v0.a;
				var config = _v0.b;
				var playback = A3($author$project$Anim$Internal$Builder$resolvePlayback, processed.t, processed.A, config.b);
				var animGroup = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups);
				var animTransformOrder = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Extra$TransformOrder$default,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getTransformOrder, animGroup));
				var propertyStatesGroup = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Internal$Engine$Shared$AnimGroups$init,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates, animGroup));
				var snapshot = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot, animGroup));
				return _Utils_Tuple2(
					animGroupName,
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeProcessedAnimGroupConfig(animGroupName)(animGroupName)(
						$elm$core$Maybe$Just(propertyStatesGroup))(
						$elm$core$Maybe$Just(animTransformOrder))(
						$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeTransformBaseline(snapshot))($elm$core$Maybe$Nothing)($elm$core$Maybe$Nothing)($elm$core$Maybe$Nothing)(config.j)(config.e)(config.f)(config.g)(
						A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$touchedAxesForGroup, animGroupName, touchedAxes))(playback.t)(playback.A)(config.s));
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toList(processed.cw));
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'type',
					$elm$json$Json$Encode$string(typeTag)),
					_Utils_Tuple2(
					'elements',
					$elm$json$Json$Encode$object(elementsWithVersions)),
					_Utils_Tuple2(
					'iterations',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeIterations(processed.t)),
					_Utils_Tuple2(
					'direction',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimationDirection(processed.A))
				]));
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
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList = A2($elm$core$Basics$composeL, $elm$core$Basics$identity, $elm$core$Dict$fromList);
var $author$project$Anim$Internal$Builder$processedPropertyMode = function (prop) {
	switch (prop.$) {
		case 0:
			var cfg = prop.c;
			return cfg.Q;
		case 1:
			var cfg = prop.b;
			return cfg.Q;
		case 2:
			var cfg = prop.a;
			return cfg.Q;
		case 3:
			var cfg = prop.a;
			return cfg.Q;
		case 4:
			var cfg = prop.a;
			return cfg.Q;
		case 5:
			var cfg = prop.a;
			return cfg.Q;
		case 6:
			var cfg = prop.a;
			return cfg.Q;
		case 7:
			var cfg = prop.a;
			return cfg.Q;
		default:
			var cfg = prop.a;
			return cfg.Q;
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$filterGroupsByMode = F2(
	function (targetMode, processed) {
		var filteredGroups = $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList(
			A2(
				$elm$core$List$filterMap,
				function (_v0) {
					var name = _v0.a;
					var config = _v0.b;
					var kept = A2(
						$elm$core$List$filter,
						function (p) {
							return _Utils_eq(
								$author$project$Anim$Internal$Builder$processedPropertyMode(p),
								targetMode);
						},
						config.s);
					return $elm$core$List$isEmpty(kept) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
						_Utils_Tuple2(
							name,
							_Utils_update(
								config,
								{s: kept})));
				},
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toList(processed.cw)));
		return _Utils_update(
			processed,
			{cw: filteredGroups});
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encode = F2(
	function (animGroups, processed) {
		return A4(
			$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimateLike,
			'animate',
			animGroups,
			$elm$core$Dict$empty,
			A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$filterGroupsByMode, $author$project$Anim$Internal$Builder$Animate, processed));
	});
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeSnap = F2(
	function (animGroups, processed) {
		return A4(
			$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimateLike,
			'snap',
			animGroups,
			$elm$core$Dict$empty,
			A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$filterGroupsByMode, $author$project$Anim$Internal$Builder$Snap, processed));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$Complete = 3;
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$NotStarted = 0;
var $author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet = F3(
	function (setter, maybeValue, baselines) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return A2(setter, value, baselines);
		} else {
			return baselines;
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds = function (properties) {
	var setBounds = F2(
		function (property, _v1) {
			var end = _v1.n;
			var start = _v1.bz;
			switch (property.$) {
				case 0:
					var cssName = property.a;
					var unit = property.b;
					var config = property.c;
					return {
						n: A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, config.n, unit, end),
						bz: A3(
							$author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet,
							function (v) {
								return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, v, unit);
							},
							config.bz,
							start)
					};
				case 1:
					var cssName = property.a;
					var config = property.b;
					return {
						n: A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, config.n, end),
						bz: A3(
							$author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet,
							$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty(cssName),
							config.bz,
							start)
					};
				case 2:
					var config = property.a;
					return {
						n: A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, config.n, end),
						bz: A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, config.bz, start)
					};
				case 3:
					var config = property.a;
					return {
						n: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
							config.E,
							A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, config.n, end)),
						bz: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
							config.E,
							A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, config.bz, start))
					};
				case 4:
					var config = property.a;
					return {
						n: A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, config.n, end),
						bz: A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, config.bz, start)
					};
				case 5:
					var config = property.a;
					return {
						n: A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, config.n, end),
						bz: A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setScale, config.bz, start)
					};
				case 6:
					var config = property.a;
					return {
						n: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
							config.E,
							A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, config.n, end)),
						bz: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
							config.E,
							A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setSize, config.bz, start))
					};
				case 7:
					var config = property.a;
					return {
						n: A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, config.n, end),
						bz: A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, config.bz, start)
					};
				default:
					var config = property.a;
					return {
						n: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits,
							config.E,
							A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, config.n, end)),
						bz: A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits,
							config.E,
							A3($author$project$Anim$Internal$Engine$WAAPI$Generator$maybeSet, $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, config.bz, start))
					};
			}
		});
	return A3(
		$elm$core$List$foldl,
		setBounds,
		{n: $author$project$Anim$Internal$Builder$PropertyBaselines$empty, bz: $author$project$Anim$Internal$Builder$PropertyBaselines$empty},
		properties);
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getCustomColorProperty = F2(
	function (cssPropertyName, _v0) {
		var dict = _v0;
		return A2(
			$elm$core$Maybe$andThen,
			function (v) {
				if (v.$ === 1) {
					var c = v.a;
					return $elm$core$Maybe$Just(c);
				} else {
					return $elm$core$Maybe$Nothing;
				}
			},
			A2($elm$core$Dict$get, 'customColor:' + cssPropertyName, dict));
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$getCustomProperty = F2(
	function (cssPropertyName, _v0) {
		var dict = _v0;
		return A2(
			$elm$core$Maybe$andThen,
			function (v) {
				if (!v.$) {
					var f = v.a;
					return $elm$core$Maybe$Just(f);
				} else {
					return $elm$core$Maybe$Nothing;
				}
			},
			A2($elm$core$Dict$get, 'custom:' + cssPropertyName, dict));
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
var $author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOrigin = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 3) {
				var po = v.a;
				return $elm$core$Maybe$Just(po);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'perspectiveOrigin', dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getSize = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 8) {
				var s = v.a;
				return $elm$core$Maybe$Just(s);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'size', dict));
};
var $author$project$Anim$Internal$Engine$WAAPI$Generator$resolveStartFromSnapshot = F2(
	function (snapshot, property) {
		var fill = F2(
			function (existing, fromSnapshot) {
				if (!existing.$) {
					return existing;
				} else {
					return fromSnapshot;
				}
			});
		switch (property.$) {
			case 8:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedTranslateConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate(snapshot))
						}));
			case 4:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedRotateConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getRotate(snapshot))
						}));
			case 7:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedSkewConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getSkew(snapshot))
						}));
			case 5:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedScaleConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getScale(snapshot))
						}));
			case 2:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedOpacityConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getOpacity(snapshot))
						}));
			case 3:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOrigin(snapshot))
						}));
			case 6:
				var config = property.a;
				return $author$project$Anim$Internal$Builder$ProcessedSizeConfig(
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								$author$project$Anim$Internal$Builder$PropertyBaselines$getSize(snapshot))
						}));
			case 0:
				var cssName = property.a;
				var unit = property.b;
				var config = property.c;
				return A3(
					$author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig,
					cssName,
					unit,
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								A2($author$project$Anim$Internal$Builder$PropertyBaselines$getCustomProperty, cssName, snapshot))
						}));
			default:
				var cssName = property.a;
				var config = property.b;
				return A2(
					$author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig,
					cssName,
					_Utils_update(
						config,
						{
							bz: A2(
								fill,
								config.bz,
								A2($author$project$Anim$Internal$Builder$PropertyBaselines$getCustomColorProperty, cssName, snapshot))
						}));
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setAnimationDirection = F2(
	function (direction, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{A: direction});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setIterationCount = F2(
	function (iterations, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{t: iterations});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates = F2(
	function (propertyStates, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{al: propertyStates});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setTransformOrder = F2(
	function (order, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{p: order});
	});
var $author$project$Anim$Internal$Engine$WAAPI$Generator$generateAnimation = F7(
	function (iterations, animationDirection, globalTransformOrder, discreteEntryProps, discreteExitProps, existingAnimation, properties) {
		var transformOrder = function () {
			if (!globalTransformOrder.$) {
				var order = globalTransformOrder.a;
				return order;
			} else {
				return A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Extra$TransformOrder$default,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getTransformOrder, existingAnimation));
			}
		}();
		var snapBounds = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds(
			A2(
				$elm$core$List$filter,
				function (p) {
					return _Utils_eq(
						$author$project$Anim$Internal$Builder$processedPropertyMode(p),
						$author$project$Anim$Internal$Builder$Snap);
				},
				properties));
		var existingPropertyVersions = A2(
			$elm$core$Maybe$withDefault,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init,
			A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates, existingAnimation));
		var animationBounds = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds(properties);
		var snapshot = function () {
			if (!existingAnimation.$) {
				var existing = existingAnimation.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$merge,
					snapBounds.n,
					A2(
						$author$project$Anim$Internal$Builder$PropertyBaselines$merge,
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot(existing),
						animationBounds.bz));
			} else {
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$merge, animationBounds.bz, snapBounds.n);
			}
		}();
		var newPropertyVersions = $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList(
			A2(
				$elm$core$List$map,
				function (property) {
					var propType = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyTypeString(property);
					var newVersion = A2(
						$elm$core$Maybe$withDefault,
						1,
						A2(
							$elm$core$Maybe$map,
							$elm$core$Basics$add(1),
							A2(
								$elm$core$Maybe$map,
								function ($) {
									return $.bH;
								},
								A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, existingPropertyVersions))));
					var initialStatus = _Utils_eq(
						$author$project$Anim$Internal$Builder$processedPropertyMode(property),
						$author$project$Anim$Internal$Builder$Snap) ? 3 : 0;
					return _Utils_Tuple2(
						propType,
						{
							I: A2($author$project$Anim$Internal$Engine$WAAPI$Generator$resolveStartFromSnapshot, snapshot, property),
							cd: initialStatus,
							bH: newVersion
						});
				},
				properties));
		var mergedPropertyVersions = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$union, newPropertyVersions, existingPropertyVersions);
		return A2(
			$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteExit,
			discreteExitProps,
			A2(
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setDiscreteEntry,
				discreteEntryProps,
				A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setAnimationDirection,
					animationDirection,
					A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setIterationCount,
						iterations,
						A2(
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setTransformOrder,
							transformOrder,
							A2(
								$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates,
								mergedPropertyVersions,
								A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot, snapshot, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$init)))))));
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
var $author$project$Anim$Internal$Builder$injectCurrentStates = F2(
	function (animGroups, _v0) {
		var data = _v0;
		var state = data.x;
		var runtimeSnapshots = A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (_v1, animation) {
					return animation.fq;
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
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.S),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
		return _Utils_update(
			data,
			{
				x: _Utils_update(
					state,
					{b9: mergedRuntimeBaselines})
			});
	});
var $author$project$Anim$Internal$Builder$process = function (_v0) {
	var data = _v0;
	var getDefaultsForGroup = function (groupName) {
		return A2(
			$elm$core$Maybe$withDefault,
			data.c,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, groupName, data.a.W));
	};
	return {
		A: data.b.A,
		i: data.c.i,
		aH: data.c.aH,
		ax: data.c.ax,
		aI: data.c.aI,
		ah: data.c.ah,
		cw: A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (groupName, group) {
					var groupDefaults = getDefaultsForGroup(groupName);
					return {
						f: function () {
							var _v1 = group.f;
							if (!_v1.$) {
								var overrides = _v1.a;
								return overrides;
							} else {
								return data.b.f;
							}
						}(),
						g: function () {
							var _v2 = group.g;
							if (!_v2.$) {
								var overrides = _v2.a;
								return overrides;
							} else {
								return data.b.g;
							}
						}(),
						h: group.h,
						e: function () {
							var _v3 = group.e;
							if (!_v3.$) {
								var axes = _v3.a;
								return axes;
							} else {
								return data.a.e;
							}
						}(),
						b: group.b,
						s: A3($author$project$Anim$Internal$Builder$processProperties, groupDefaults, groupName, group.s),
						p: function () {
							var _v4 = group.p;
							if (!_v4.$) {
								return group.p;
							} else {
								return groupDefaults.aJ;
							}
						}(),
						j: A2($elm$core$Maybe$withDefault, data.j, group.j),
						k: group.k,
						l: group.l
					};
				}),
			data.a.C),
		t: data.b.t
	};
};
var $author$project$Anim$Internal$Engine$WAAPI$setSnapshot = function (anims) {
	return A2(
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
		F2(
			function (_v0, anim) {
				return {
					fq: $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot(anim)
				};
			}),
		anims);
};
var $author$project$Anim$Internal$Engine$WAAPI$animate = F2(
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
						A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$addPropertyStates, animGroup, existing),
						acc);
				}
			});
		var builder = build(
			A2(
				$author$project$Anim$Internal$Builder$injectCurrentStates,
				$author$project$Anim$Internal$Engine$WAAPI$setSnapshot(animGroups),
				state.q));
		var processed = $author$project$Anim$Internal$Builder$process(builder);
		var generateAnimGroup = F2(
			function (animGroupName, config) {
				var playback = A3($author$project$Anim$Internal$Builder$resolvePlayback, processed.t, processed.A, config.b);
				return A7(
					$author$project$Anim$Internal$Engine$WAAPI$Generator$generateAnimation,
					playback.t,
					playback.A,
					config.p,
					A2($author$project$Anim$Internal$Builder$getDiscreteEntryPropertiesFor, animGroupName, builder),
					A2($author$project$Anim$Internal$Builder$getDiscreteExitPropertiesFor, animGroupName, builder),
					A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups),
					config.s);
			});
		var hasSnap = A2(
			$elm$core$List$any,
			function (config) {
				return A2(
					$elm$core$List$any,
					function (p) {
						return _Utils_eq(
							$author$project$Anim$Internal$Builder$processedPropertyMode(p),
							$author$project$Anim$Internal$Builder$Snap);
					},
					config.s);
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(processed.cw));
		var processedAnimGroups = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
			insertAnimGroup,
			animGroups,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, generateAnimGroup, processed.cw));
		var nextState = A2(
			$author$project$Anim$Internal$Engine$WAAPI$AnimState,
			_Utils_update(
				state,
				{
					q: $author$project$Anim$Internal$Builder$clearAnimData(
						$author$project$Anim$Internal$Builder$mergeBaselines(
							A2($author$project$Anim$Internal$Builder$addAnimationToHistory, processed, builder))),
					_: true
				}),
			processedAnimGroups);
		var animateCmd = $elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[
					state.M(
					A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$encode, processedAnimGroups, processed)),
					hasSnap ? state.M(
					A2($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeSnap, processedAnimGroups, processed)) : $elm$core$Platform$Cmd$none
				]));
		return _Utils_Tuple2(nextState, animateCmd);
	});
var $author$project$Anim$Engine$WAAPI$animate = $author$project$Anim$Internal$Engine$WAAPI$animate;
var $author$project$Motion$Easing$BounceOut = {$: 4};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSize = 12;
var $author$project$Anim$Property$Translate$begin = function (animBuilder) {
	var _v0 = $author$project$Anim$Internal$Builder$getCurrentAnimGroupName(animBuilder);
	if (!_v0.$) {
		var animGroupName = _v0.a;
		return A2($author$project$Anim$Internal$Builder$Translate$for, animGroupName, animBuilder);
	} else {
		return A2($author$project$Anim$Internal$Builder$Translate$for, '', animBuilder);
	}
};
var $author$project$Anim$Internal$Builder$Property$easing = F2(
	function (easing_, config) {
		return _Utils_update(
			config,
			{
				bW: $elm$core$Maybe$Just(easing_),
				by: $elm$core$Maybe$Nothing
			});
	});
var $author$project$Anim$Internal$Builder$Translate$easing = F2(
	function (easing_, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			A2($author$project$Anim$Internal$Builder$Property$easing, easing_, config),
			builder);
	});
var $author$project$Anim$Property$Translate$easing = $author$project$Anim$Internal$Builder$Translate$easing;
var $author$project$Anim$Property$Translate$end = $author$project$Anim$Internal$Builder$Translate$build;
var $author$project$Shared$TimeSpec$Speed = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Builder$Property$speed = F2(
	function (value, config) {
		return _Utils_update(
			config,
			{
				cf: $elm$core$Maybe$Just(
					$author$project$Shared$TimeSpec$Speed(value))
			});
	});
var $author$project$Anim$Internal$Builder$Translate$speed = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			A2($author$project$Anim$Internal$Builder$Property$speed, value, config),
			builder);
	});
var $author$project$Anim$Property$Translate$speed = $author$project$Anim$Internal$Builder$Translate$speed;
var $author$project$Anim$Property$Translate$toY = $author$project$Anim$Internal$Builder$Translate$toY;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$dropBall = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Property$Translate$begin,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Property$Translate$fromY(0),
		A2(
			$elm$core$Basics$composeR,
			$author$project$Anim$Property$Translate$toY(100 - $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSize),
			A2(
				$elm$core$Basics$composeR,
				$author$project$Anim$Property$Translate$speed(75),
				A2(
					$elm$core$Basics$composeR,
					$author$project$Anim$Property$Translate$easing($author$project$Motion$Easing$BounceOut),
					$author$project$Anim$Property$Translate$end)))));
var $author$project$Anim$Engine$WAAPI$for = $author$project$Anim$Internal$Builder$for;
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeCommandWithProperties = F3(
	function (commandType, animGroupName, maybeProperties) {
		var propertyField = function () {
			if (!maybeProperties.$) {
				var props = maybeProperties.a;
				return _List_fromArray(
					[
						_Utils_Tuple2(
						'properties',
						A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, props))
					]);
			} else {
				return _List_Nil;
			}
		}();
		var baseFields = _List_fromArray(
			[
				_Utils_Tuple2(
				'type',
				$elm$json$Json$Encode$string(commandType)),
				_Utils_Tuple2(
				'elementId',
				$elm$json$Json$Encode$string(animGroupName))
			]);
		return $elm$json$Json$Encode$object(
			_Utils_ap(baseFields, propertyField));
	});
var $author$project$Anim$Internal$Engine$WAAPI$pause = F2(
	function (animGroupName, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		return _Utils_Tuple2(
			A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, animGroups),
			state.M(
				A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeCommandWithProperties, 'pause', animGroupName, $elm$core$Maybe$Nothing)));
	});
var $author$project$Anim$Engine$WAAPI$pause = $author$project$Anim$Internal$Engine$WAAPI$pause;
var $author$project$Anim$Internal$Builder$getLatestAnimateConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Maybe$andThen,
			function (h) {
				var isAnimate = function (entry) {
					var _v2 = entry.cA;
					if (!_v2) {
						return true;
					} else {
						return false;
					}
				};
				return function (result) {
					if (!result.$) {
						return result;
					} else {
						return $elm$core$Maybe$Just(h.aG.I);
					}
				}(
					A2(
						$elm$core$Maybe$map,
						function ($) {
							return $.I;
						},
						$elm$core$List$head(
							A2(
								$elm$core$List$filter,
								isAnimate,
								A2($elm$core$List$cons, h.aG, h.bi)))));
			},
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.x.aC));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$Running = 1;
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$isRunning = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups,
		$elm$core$List$any(
			function (prop) {
				return prop.cd === 1;
			})));
var $author$project$Anim$Internal$Builder$extractProcessedPropertyBaseline = F2(
	function (propConfig, baselines) {
		switch (propConfig.$) {
			case 8:
				var cfg = propConfig.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslateUnits,
					cfg.E,
					A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, cfg.n, baselines));
			case 4:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, cfg.n, baselines);
			case 5:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, cfg.n, baselines);
			case 7:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, cfg.n, baselines);
			case 2:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, cfg.n, baselines);
			case 3:
				var cfg = propConfig.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOriginUnits,
					cfg.E,
					A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, cfg.n, baselines));
			case 6:
				var cfg = propConfig.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSizeUnits,
					cfg.E,
					A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, cfg.n, baselines));
			case 0:
				var cssName = propConfig.a;
				var unit = propConfig.b;
				var cfg = propConfig.c;
				return A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, cfg.n, unit, baselines);
			default:
				var cssName = propConfig.a;
				var cfg = propConfig.b;
				return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, cfg.n, baselines);
		}
	});
var $author$project$Anim$Internal$Builder$setBaselinesFromProcessedEnds = F3(
	function (animGroupName, props, _v0) {
		var data = _v0;
		var state = data.x;
		var existing = A2(
			$elm$core$Maybe$withDefault,
			$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, state.S));
		var merged = A3($elm$core$List$foldl, $author$project$Anim$Internal$Builder$extractProcessedPropertyBaseline, existing, props);
		return _Utils_update(
			data,
			{
				x: _Utils_update(
					state,
					{
						S: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, merged, state.S)
					})
			});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setProgress = F2(
	function (progress, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{X: progress});
	});
var $author$project$Anim$Internal$Engine$WAAPI$resetSingleKey = F2(
	function (animGroupName, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var _v1 = A2($author$project$Anim$Internal$Builder$getLatestAnimateConfig, animGroupName, state.q);
		if (_v1.$ === 1) {
			return _Utils_Tuple2(
				A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, animGroups),
				$elm$core$Platform$Cmd$none);
		} else {
			var properties = _v1.a.s;
			var startStates = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds(properties).bz;
			var rewoundBuilder = A3($author$project$Anim$Internal$Builder$setBaselinesFromProcessedEnds, animGroupName, properties, state.q);
			var resetCmd = state.M(
				A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeCommandWithProperties, 'reset', animGroupName, $elm$core$Maybe$Nothing));
			var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups);
			if (_v2.$ === 1) {
				var newAnimGroup = A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot, startStates, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$init);
				return _Utils_Tuple2(
					A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimState,
						_Utils_update(
							state,
							{q: rewoundBuilder, _: false}),
						A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, newAnimGroup, animGroups)),
					resetCmd);
			} else {
				var animGroup = _v2.a;
				var resetAnimGroup = A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setProgress,
					0,
					A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates,
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$init,
						A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot, startStates, animGroup)));
				var updatedAnimGroups = A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, resetAnimGroup, animGroups);
				return _Utils_Tuple2(
					A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimState,
						_Utils_update(
							state,
							{
								q: rewoundBuilder,
								_: A2(
									$elm$core$List$any,
									$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$isRunning,
									$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(updatedAnimGroups))
							}),
						updatedAnimGroups),
					resetCmd);
			}
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$reset = F2(
	function (animGroupName, animState) {
		return A2($author$project$Anim$Internal$Engine$WAAPI$resetSingleKey, animGroupName, animState);
	});
var $author$project$Anim$Engine$WAAPI$reset = $author$project$Anim$Internal$Engine$WAAPI$reset;
var $author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeRestart = F4(
	function (iterationsConfig, directionConfig, animGroup, configGroup) {
		var elementsWithVersions = A2(
			$elm$core$List$map,
			function (_v0) {
				var animGroupName = _v0.a;
				var config = _v0.b;
				var playback = A3($author$project$Anim$Internal$Builder$resolvePlayback, iterationsConfig, directionConfig, config.b);
				var elementAnim = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroup);
				var elementProps = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Internal$Engine$Shared$AnimGroups$init,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates, elementAnim));
				var snapshot = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot, elementAnim));
				var elemTransformOrder = A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Extra$TransformOrder$default,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getTransformOrder, elementAnim));
				return _Utils_Tuple2(
					animGroupName,
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeProcessedAnimGroupConfig(animGroupName)(animGroupName)(
						$elm$core$Maybe$Just(elementProps))(
						$elm$core$Maybe$Just(elemTransformOrder))(
						$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeTransformBaseline(snapshot))($elm$core$Maybe$Nothing)($elm$core$Maybe$Nothing)($elm$core$Maybe$Nothing)(config.j)(config.e)(config.f)(config.g)($elm$core$Dict$empty)(playback.t)(playback.A)(config.s));
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toList(configGroup));
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'type',
					$elm$json$Json$Encode$string('animate')),
					_Utils_Tuple2(
					'elements',
					$elm$json$Json$Encode$object(elementsWithVersions)),
					_Utils_Tuple2(
					'iterations',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeIterations(iterationsConfig)),
					_Utils_Tuple2(
					'direction',
					$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeAnimationDirection(directionConfig)),
					_Utils_Tuple2(
					'isRestart',
					$elm$json$Json$Encode$bool(true))
				]));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$foldResizeStates = F3(
	function (f, acc, _v0) {
		var group = _v0;
		return A3($elm$core$Dict$foldl, f, acc, group.a6);
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getAnimationDirection = function (_v0) {
	var group = _v0;
	return group.A;
};
var $author$project$Anim$Internal$Builder$getCurrentAnimationConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Maybe$map,
			A2(
				$elm$core$Basics$composeR,
				function ($) {
					return $.aG;
				},
				function ($) {
					return $.I;
				}),
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.x.aC));
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getIterations = function (_v0) {
	var group = _v0;
	return group.t;
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$fromRecord = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$WAAPI$rebasePerspectiveOriginConfig = F2(
	function (cached, config) {
		if (config.$ === 3) {
			var cfg = config.a;
			return $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig(
				_Utils_update(
					cfg,
					{
						y: $elm$core$Basics$round(cached.d),
						n: $author$project$Anim$Internal$Property$PerspectiveOrigin$fromRecord(
							{ar: cached.n.ar, as: cached.n.as}),
						bz: $elm$core$Maybe$Just(
							$author$project$Anim$Internal$Property$PerspectiveOrigin$fromRecord(
								{ar: cached.bz.ar, as: cached.bz.as}))
					}));
		} else {
			return config;
		}
	});
var $author$project$Anim$Internal$Property$Scale$fromRecord = $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Engine$WAAPI$rebaseScaleConfig = F2(
	function (cached, config) {
		if (config.$ === 5) {
			var cfg = config.a;
			return $author$project$Anim$Internal$Builder$ProcessedScaleConfig(
				_Utils_update(
					cfg,
					{
						y: $elm$core$Basics$round(cached.d),
						n: $author$project$Anim$Internal$Property$Scale$fromRecord(cached.n),
						bz: $elm$core$Maybe$Just(
							$author$project$Anim$Internal$Property$Scale$fromRecord(cached.bz))
					}));
		} else {
			return config;
		}
	});
var $author$project$Anim$Internal$Property$Size$fromRecord = function (record) {
	return {c2: record.c3, R: record.dN};
};
var $author$project$Anim$Internal$Engine$WAAPI$rebaseSizeConfig = F2(
	function (cached, config) {
		if (config.$ === 6) {
			var cfg = config.a;
			return $author$project$Anim$Internal$Builder$ProcessedSizeConfig(
				_Utils_update(
					cfg,
					{
						y: $elm$core$Basics$round(cached.d),
						n: $author$project$Anim$Internal$Property$Size$fromRecord(
							{c3: cached.n.as, dN: cached.n.ar}),
						bz: $elm$core$Maybe$Just(
							$author$project$Anim$Internal$Property$Size$fromRecord(
								{c3: cached.bz.as, dN: cached.bz.ar}))
					}));
		} else {
			return config;
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$rebaseTranslateConfig = F2(
	function (cached, config) {
		if (config.$ === 8) {
			var cfg = config.a;
			return $author$project$Anim$Internal$Builder$ProcessedTranslateConfig(
				_Utils_update(
					cfg,
					{
						y: $elm$core$Basics$round(cached.d),
						n: $author$project$Anim$Internal$Property$Translate$fromRecord(cached.n),
						bz: $elm$core$Maybe$Just(
							$author$project$Anim$Internal$Property$Translate$fromRecord(cached.bz))
					}));
		} else {
			return config;
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$rebaseFor = function (propName) {
	switch (propName) {
		case 'translate':
			return $elm$core$Maybe$Just($author$project$Anim$Internal$Engine$WAAPI$rebaseTranslateConfig);
		case 'scale':
			return $elm$core$Maybe$Just($author$project$Anim$Internal$Engine$WAAPI$rebaseScaleConfig);
		case 'perspectiveOrigin':
			return $elm$core$Maybe$Just($author$project$Anim$Internal$Engine$WAAPI$rebasePerspectiveOriginConfig);
		case 'size':
			return $elm$core$Maybe$Just($author$project$Anim$Internal$Engine$WAAPI$rebaseSizeConfig);
		default:
			return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Dict$singleton = F2(
	function (key, value) {
		return A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$singleton = F2(
	function (name, value) {
		return A2($elm$core$Dict$singleton, name, value);
	});
var $author$project$Anim$Internal$Engine$WAAPI$restartSingleKey = F2(
	function (resolvedKey, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var _v1 = A2($author$project$Anim$Internal$Builder$getCurrentAnimationConfig, resolvedKey, state.q);
		if (_v1.$ === 1) {
			return _Utils_Tuple2(
				A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, animGroups),
				$elm$core$Platform$Cmd$none);
		} else {
			var processedData = _v1.a;
			var startStates = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds(processedData.s).bz;
			var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, resolvedKey, animGroups);
			if (_v2.$ === 1) {
				var newProperties = $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList(
					A2(
						$elm$core$List$map,
						function (p) {
							return _Utils_Tuple2(
								$author$project$Anim$Internal$Engine$WAAPI$Generator$propertyTypeString(p),
								{I: p, cd: 0, bH: 1});
						},
						processedData.s));
				var newAnimGroup = A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates,
					newProperties,
					A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot, startStates, $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$init));
				var updatedElementAnimations = A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, resolvedKey, newAnimGroup, animGroups);
				var updatedAnimState = A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimState,
					_Utils_update(
						state,
						{_: true}),
					updatedElementAnimations);
				return _Utils_Tuple2(
					updatedAnimState,
					state.M(
						A4(
							$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeRestart,
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getIterations(newAnimGroup),
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getAnimationDirection(newAnimGroup),
							updatedElementAnimations,
							A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$singleton, resolvedKey, processedData))));
			} else {
				var animGroup = _v2.a;
				var rebasedProcessedData = A3(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$foldResizeStates,
					F3(
						function (propName, cached, acc) {
							var _v3 = $author$project$Anim$Internal$Engine$WAAPI$rebaseFor(propName);
							if (!_v3.$) {
								var rebase = _v3.a;
								return _Utils_update(
									acc,
									{
										s: A2(
											$elm$core$List$map,
											rebase(cached),
											acc.s)
									});
							} else {
								return acc;
							}
						}),
					processedData,
					animGroup);
				var rebasedStartStates = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds(rebasedProcessedData.s).bz;
				var updatedProperties = A3(
					$elm$core$List$foldl,
					F2(
						function (property, acc) {
							var propType = $author$project$Anim$Internal$Engine$WAAPI$Generator$propertyTypeString(property);
							var newVersion = A2(
								$elm$core$Maybe$withDefault,
								1,
								A2(
									$elm$core$Maybe$map,
									$elm$core$Basics$add(1),
									A2(
										$elm$core$Maybe$map,
										function ($) {
											return $.bH;
										},
										A2(
											$author$project$Anim$Internal$Engine$Shared$AnimGroups$get,
											propType,
											$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates(animGroup)))));
							return A3(
								$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
								propType,
								{I: property, cd: 0, bH: newVersion},
								acc);
						}),
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates(animGroup),
					rebasedProcessedData.s);
				var resetElementAnimation = A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setProgress,
					0,
					A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates,
						updatedProperties,
						A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot, rebasedStartStates, animGroup)));
				var updatedElementAnimations = A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, resolvedKey, resetElementAnimation, animGroups);
				var updatedAnimState = A2(
					$author$project$Anim$Internal$Engine$WAAPI$AnimState,
					_Utils_update(
						state,
						{_: true}),
					updatedElementAnimations);
				return _Utils_Tuple2(
					updatedAnimState,
					state.M(
						A4(
							$author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeRestart,
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getIterations(animGroup),
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getAnimationDirection(animGroup),
							updatedElementAnimations,
							A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$singleton, resolvedKey, rebasedProcessedData))));
			}
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$restart = F2(
	function (animGroup, animState) {
		return A2($author$project$Anim$Internal$Engine$WAAPI$restartSingleKey, animGroup, animState);
	});
var $author$project$Anim$Engine$WAAPI$restart = $author$project$Anim$Internal$Engine$WAAPI$restart;
var $author$project$Anim$Internal$Engine$WAAPI$resume = F2(
	function (animGroup, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		return _Utils_Tuple2(
			A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, animGroups),
			state.M(
				A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeCommandWithProperties, 'resume', animGroup, $elm$core$Maybe$Nothing)));
	});
var $author$project$Anim$Engine$WAAPI$resume = $author$project$Anim$Internal$Engine$WAAPI$resume;
var $author$project$Anim$Internal$Engine$WAAPI$stop = F2(
	function (animGroupName, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var endStates = A2(
			$elm$core$Maybe$withDefault,
			$author$project$Anim$Internal$Builder$PropertyBaselines$empty,
			A2(
				$elm$core$Maybe$map,
				A2(
					$elm$core$Basics$composeR,
					function ($) {
						return $.s;
					},
					A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Internal$Engine$WAAPI$Generator$propertyBounds,
						function ($) {
							return $.n;
						})),
				A2($author$project$Anim$Internal$Builder$getCurrentAnimationConfig, animGroupName, state.q)));
		var updatedElementAnimations = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
			animGroupName,
			$elm$core$Maybe$map(
				function (anim) {
					return A2(
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot,
						A2(
							$author$project$Anim$Internal$Builder$PropertyBaselines$merge,
							$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot(anim),
							endStates),
						anim);
				}),
			animGroups);
		return _Utils_Tuple2(
			A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, updatedElementAnimations),
			state.M(
				A3($author$project$Anim$Internal$Engine$WAAPI$Encoder$encodeCommandWithProperties, 'stop', animGroupName, $elm$core$Maybe$Nothing)));
	});
var $author$project$Anim$Engine$WAAPI$stop = $author$project$Anim$Internal$Engine$WAAPI$stop;
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $author$project$Anim$Engine$WAAPI$AnimError = function (a) {
	return {$: 9, a: a};
};
var $author$project$Anim$Engine$WAAPI$Cancelled = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Anim$Engine$WAAPI$Ended = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Engine$WAAPI$Iteration = F2(
	function (a, b) {
		return {$: 7, a: a, b: b};
	});
var $author$project$Anim$Engine$WAAPI$Paused = F2(
	function (a, b) {
		return {$: 5, a: a, b: b};
	});
var $author$project$Anim$Engine$WAAPI$Progress = F2(
	function (a, b) {
		return {$: 8, a: a, b: b};
	});
var $author$project$Anim$Engine$WAAPI$Restarted = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Engine$WAAPI$Resumed = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Engine$WAAPI$Run = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Engine$WAAPI$Started = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Engine$WAAPI$toAnimEvent = function (internalEvent) {
	switch (internalEvent.$) {
		case 0:
			var animGroup = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$Run(animGroup);
		case 1:
			var animGroup = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$Started(animGroup);
		case 2:
			var animGroup = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$Ended(animGroup);
		case 3:
			var animGroup = internalEvent.a;
			var progress = internalEvent.b;
			return A2($author$project$Anim$Engine$WAAPI$Cancelled, animGroup, progress);
		case 4:
			var animGroup = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$Restarted(animGroup);
		case 5:
			var animGroup = internalEvent.a;
			var progress = internalEvent.b;
			return A2($author$project$Anim$Engine$WAAPI$Paused, animGroup, progress);
		case 6:
			var animGroup = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$Resumed(animGroup);
		case 7:
			var animGroup = internalEvent.a;
			var count = internalEvent.b;
			return A2($author$project$Anim$Engine$WAAPI$Iteration, animGroup, count);
		case 8:
			var animGroup = internalEvent.a;
			var progress = internalEvent.b;
			return A2($author$project$Anim$Engine$WAAPI$Progress, animGroup, progress);
		default:
			var errorMsg = internalEvent.a;
			return $author$project$Anim$Engine$WAAPI$AnimError(errorMsg);
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimError = function (a) {
	return {$: 9, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$Progress = F2(
	function (a, b) {
		return {$: 8, a: a, b: b};
	});
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$json$Json$Decode$map3 = _Json_map3;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $author$project$Anim$Internal$Engine$WAAPI$Cancelled = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$WAAPI$Ended = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$Iteration = F2(
	function (a, b) {
		return {$: 7, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$WAAPI$Paused = F2(
	function (a, b) {
		return {$: 5, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$WAAPI$Restarted = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$Resumed = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$Run = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$Started = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$WAAPI$statusToAnimEvent = F3(
	function (animGroupName, status, progress) {
		switch (status) {
			case 'run':
				return $author$project$Anim$Internal$Engine$WAAPI$Run(animGroupName);
			case 'started':
				return $author$project$Anim$Internal$Engine$WAAPI$Started(animGroupName);
			case 'paused':
				return A2($author$project$Anim$Internal$Engine$WAAPI$Paused, animGroupName, progress);
			case 'resumed':
				return $author$project$Anim$Internal$Engine$WAAPI$Resumed(animGroupName);
			case 'completed':
				return $author$project$Anim$Internal$Engine$WAAPI$Ended(animGroupName);
			case 'cancelled':
				return A2($author$project$Anim$Internal$Engine$WAAPI$Cancelled, animGroupName, progress);
			case 'stopped':
				return $author$project$Anim$Internal$Engine$WAAPI$Ended(animGroupName);
			case 'reset':
				return A2($author$project$Anim$Internal$Engine$WAAPI$Cancelled, animGroupName, progress);
			case 'restarted':
				return $author$project$Anim$Internal$Engine$WAAPI$Restarted(animGroupName);
			case 'iteration':
				return A2(
					$author$project$Anim$Internal$Engine$WAAPI$Iteration,
					animGroupName,
					$elm$core$Basics$round(progress));
			default:
				var invalid = status;
				return $author$project$Anim$Internal$Engine$WAAPI$AnimError('Unknown status: ' + invalid);
		}
	});
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Anim$Internal$Engine$WAAPI$animEventDecoder = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Anim$Internal$Engine$WAAPI$statusToAnimEvent,
	$elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$json$Json$Decode$at,
				_List_fromArray(
					['payload', 'animGroup']),
				$elm$json$Json$Decode$string),
				A2(
				$elm$json$Json$Decode$at,
				_List_fromArray(
					['payload', 'elementId']),
				$elm$json$Json$Decode$string)
			])),
	A2(
		$elm$json$Json$Decode$at,
		_List_fromArray(
			['payload', 'status']),
		$elm$json$Json$Decode$string),
	A2(
		$elm$json$Json$Decode$at,
		_List_fromArray(
			['payload', 'progress']),
		$elm$json$Json$Decode$float));
var $author$project$Anim$Internal$Engine$WAAPI$AnimationUpdate = F5(
	function (animGroupName, progress, isAnimating, propertyVersions, propertyProgress) {
		return {aB: animGroupName, da: isAnimating, X: progress, dv: propertyProgress, cE: propertyVersions};
	});
var $author$project$Anim$Internal$Engine$WAAPI$andMap = $elm$json$Json$Decode$map2($elm$core$Basics$apR);
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $elm$json$Json$Decode$keyValuePairs = _Json_decodeKeyValuePairs;
var $elm$json$Json$Decode$dict = function (decoder) {
	return A2(
		$elm$json$Json$Decode$map,
		$elm$core$Dict$fromList,
		$elm$json$Json$Decode$keyValuePairs(decoder));
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromDict = $elm$core$Basics$identity;
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$Anim$Internal$Engine$WAAPI$propertyVersionDecoder = A2(
	$elm$json$Json$Decode$map,
	$author$project$Anim$Internal$Engine$Shared$AnimGroups$fromDict,
	A2(
		$elm$json$Json$Decode$field,
		'propertyVersions',
		$elm$json$Json$Decode$dict($elm$json$Json$Decode$int)));
var $author$project$Anim$Internal$Engine$WAAPI$animationUpdateDecoder = A2(
	$author$project$Anim$Internal$Engine$WAAPI$andMap,
	$elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$json$Json$Decode$field,
				'propertyProgress',
				$elm$json$Json$Decode$dict($elm$json$Json$Decode$float)),
				$elm$json$Json$Decode$succeed($elm$core$Dict$empty)
			])),
	A2(
		$author$project$Anim$Internal$Engine$WAAPI$andMap,
		$author$project$Anim$Internal$Engine$WAAPI$propertyVersionDecoder,
		A2(
			$author$project$Anim$Internal$Engine$WAAPI$andMap,
			A2($elm$json$Json$Decode$field, 'isAnimating', $elm$json$Json$Decode$bool),
			A2(
				$author$project$Anim$Internal$Engine$WAAPI$andMap,
				$elm$json$Json$Decode$oneOf(
					_List_fromArray(
						[
							A2($elm$json$Json$Decode$field, 'progress', $elm$json$Json$Decode$float),
							$elm$json$Json$Decode$succeed(0)
						])),
				A2(
					$author$project$Anim$Internal$Engine$WAAPI$andMap,
					$elm$json$Json$Decode$oneOf(
						_List_fromArray(
							[
								A2($elm$json$Json$Decode$field, 'animGroup', $elm$json$Json$Decode$string),
								A2($elm$json$Json$Decode$field, 'elementId', $elm$json$Json$Decode$string)
							])),
					$elm$json$Json$Decode$succeed($author$project$Anim$Internal$Engine$WAAPI$AnimationUpdate))))));
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $author$project$Anim$Internal$Engine$WAAPI$FrozenAxesPayload = F6(
	function (animGroup, translate, scale, rotate, skew, commandVersion) {
		return {bL: animGroup, er: commandVersion, b7: rotate, ca: scale, cb: skew, ci: translate};
	});
var $elm$json$Json$Decode$map6 = _Json_map6;
var $author$project$Anim$Internal$Engine$WAAPI$frozenAxesDecoder = function () {
	var vectorDecoder = A4(
		$elm$json$Json$Decode$map3,
		F3(
			function (x, y, z) {
				return {ar: x, as: y, at: z};
			}),
		A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'z', $elm$json$Json$Decode$float));
	var skewVectorDecoder = A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (x, y) {
				return {ar: x, as: y};
			}),
		A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$float));
	return A7(
		$elm$json$Json$Decode$map6,
		$author$project$Anim$Internal$Engine$WAAPI$FrozenAxesPayload,
		A2($elm$json$Json$Decode$field, 'animGroup', $elm$json$Json$Decode$string),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['frozenStates', 'translate']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['frozenStates', 'scale']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['frozenStates', 'rotate']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['frozenStates', 'skew']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, skewVectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$field,
					'commandVersion',
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, $elm$json$Json$Decode$int)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])));
}();
var $author$project$Anim$Internal$Builder$getEmitProgressFor = F2(
	function (animGroupName, builder) {
		var data = builder;
		var globalEnabled = data.h;
		var fromHistory = A2(
			$elm$core$Maybe$andThen,
			function ($) {
				return $.h;
			},
			A2($author$project$Anim$Internal$Builder$getCurrentAnimationConfig, animGroupName, builder));
		var fromCurrentConfig = A2(
			$elm$core$Maybe$andThen,
			function ($) {
				return $.h;
			},
			A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder));
		return A2(
			$elm$core$Maybe$withDefault,
			A2($elm$core$Maybe$withDefault, globalEnabled, fromCurrentConfig),
			fromHistory);
	});
var $author$project$Anim$Internal$Property$Rotate$fromRecord = $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Property$Skew$fromRecord = function (record) {
	return {ar: record.ar, as: record.as};
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$updateRuntimeBaseline = F2(
	function (updater, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{
				fq: updater(group.fq)
			});
	});
var $author$project$Anim$Internal$Engine$WAAPI$handleFrozenAxesAcknowledgment = F2(
	function (frozen, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var updateBaseline = function (baseline) {
			return function () {
				var _v4 = frozen.cb;
				if (!_v4.$) {
					var s = _v4.a;
					return $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew(
						$author$project$Anim$Internal$Property$Skew$fromRecord(
							{ar: s.ar, as: s.as}));
				} else {
					return $elm$core$Basics$identity;
				}
			}()(
				function () {
					var _v3 = frozen.b7;
					if (!_v3.$) {
						var r = _v3.a;
						return $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate(
							$author$project$Anim$Internal$Property$Rotate$fromRecord(
								{ar: r.ar, as: r.as, at: r.at}));
					} else {
						return $elm$core$Basics$identity;
					}
				}()(
					function () {
						var _v2 = frozen.ca;
						if (!_v2.$) {
							var s = _v2.a;
							return $author$project$Anim$Internal$Builder$PropertyBaselines$setScale(
								$author$project$Anim$Internal$Property$Scale$fromRecord(
									{ar: s.ar, as: s.as, at: s.at}));
						} else {
							return $elm$core$Basics$identity;
						}
					}()(
						function () {
							var _v1 = frozen.ci;
							if (!_v1.$) {
								var t = _v1.a;
								return $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate(
									$author$project$Anim$Internal$Property$Translate$fromRecord(
										{ar: t.ar, as: t.as, at: t.at}));
							} else {
								return $elm$core$Basics$identity;
							}
						}()(baseline))));
		};
		var updatedAnimGroups = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
			frozen.bL,
			$elm$core$Maybe$map(
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$updateRuntimeBaseline(updateBaseline)),
			animGroups);
		return A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, updatedAnimGroups);
	});
var $author$project$Anim$Internal$Engine$WAAPI$animEventGroupName = function (animEvent) {
	switch (animEvent.$) {
		case 0:
			var name = animEvent.a;
			return name;
		case 1:
			var name = animEvent.a;
			return name;
		case 2:
			var name = animEvent.a;
			return name;
		case 3:
			var name = animEvent.a;
			return name;
		case 4:
			var name = animEvent.a;
			return name;
		case 5:
			var name = animEvent.a;
			return name;
		case 6:
			var name = animEvent.a;
			return name;
		case 7:
			var name = animEvent.a;
			return name;
		case 8:
			var name = animEvent.a;
			return name;
		default:
			return '';
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$Paused = 2;
var $author$project$Anim$Internal$Engine$WAAPI$animEventToStatus = function (animEvent) {
	switch (animEvent.$) {
		case 0:
			return 1;
		case 1:
			return 1;
		case 2:
			return 3;
		case 3:
			return 3;
		case 4:
			return 1;
		case 5:
			return 2;
		case 6:
			return 1;
		case 7:
			return 1;
		case 8:
			return 1;
		default:
			return 3;
	}
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setCurrentIteration = F2(
	function (currentIteration, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{av: currentIteration});
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setStatus = F2(
	function (newStatus, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{
				al: A2(
					$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
					F2(
						function (_v1, propAnim) {
							return _Utils_update(
								propAnim,
								{cd: newStatus});
						}),
					group.al)
			});
	});
var $author$project$Anim$Internal$Engine$WAAPI$handleLifecycleEvent = F2(
	function (animEvent, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var newStatus = $author$project$Anim$Internal$Engine$WAAPI$animEventToStatus(animEvent);
		var applyIteration = function () {
			if (animEvent.$ === 7) {
				var iter = animEvent.b;
				return $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setCurrentIteration(iter);
			} else {
				return $elm$core$Basics$identity;
			}
		}();
		var animGroupName = $author$project$Anim$Internal$Engine$WAAPI$animEventGroupName(animEvent);
		var updatedAnimGroups = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
			animGroupName,
			$elm$core$Maybe$map(
				A2(
					$elm$core$Basics$composeR,
					$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setStatus(newStatus),
					A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setProgress(
							function () {
								switch (animEvent.$) {
									case 5:
										var progress = animEvent.b;
										return progress;
									case 3:
										var progress = animEvent.b;
										return progress;
									case 8:
										var progress = animEvent.b;
										return progress;
									default:
										return 0;
								}
							}()),
						applyIteration))),
			animGroups);
		return A2(
			$author$project$Anim$Internal$Engine$WAAPI$AnimState,
			_Utils_update(
				state,
				{
					_: A2(
						$elm$core$List$any,
						$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$isRunning,
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(updatedAnimGroups))
				}),
			updatedAnimGroups);
	});
var $author$project$Anim$Internal$Engine$WAAPI$handleSettledValues = F2(
	function (settled, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var updateBaseline = function (baseline) {
			return function () {
				var _v4 = settled.cb;
				if (!_v4.$) {
					var s = _v4.a;
					return $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew(
						$author$project$Anim$Internal$Property$Skew$fromRecord(
							{ar: s.ar, as: s.as}));
				} else {
					return $elm$core$Basics$identity;
				}
			}()(
				function () {
					var _v3 = settled.b7;
					if (!_v3.$) {
						var r = _v3.a;
						return $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate(
							$author$project$Anim$Internal$Property$Rotate$fromRecord(
								{ar: r.ar, as: r.as, at: r.at}));
					} else {
						return $elm$core$Basics$identity;
					}
				}()(
					function () {
						var _v2 = settled.ca;
						if (!_v2.$) {
							var s = _v2.a;
							return $author$project$Anim$Internal$Builder$PropertyBaselines$setScale(
								$author$project$Anim$Internal$Property$Scale$fromRecord(
									{ar: s.ar, as: s.as, at: s.at}));
						} else {
							return $elm$core$Basics$identity;
						}
					}()(
						function () {
							var _v1 = settled.ci;
							if (!_v1.$) {
								var t = _v1.a;
								return $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate(
									$author$project$Anim$Internal$Property$Translate$fromRecord(
										{ar: t.ar, as: t.as, at: t.at}));
							} else {
								return $elm$core$Basics$identity;
							}
						}()(baseline))));
		};
		var updatedAnimGroups = A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
			settled.bL,
			$elm$core$Maybe$map(
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$updateRuntimeBaseline(updateBaseline)),
			animGroups);
		return A2($author$project$Anim$Internal$Engine$WAAPI$AnimState, state, updatedAnimGroups);
	});
var $author$project$Anim$Internal$Engine$WAAPI$SettledValuesPayload = F5(
	function (animGroup, translate, scale, rotate, skew) {
		return {bL: animGroup, b7: rotate, ca: scale, cb: skew, ci: translate};
	});
var $elm$json$Json$Decode$map5 = _Json_map5;
var $author$project$Anim$Internal$Engine$WAAPI$settledValuesDecoder = function () {
	var vectorDecoder = A4(
		$elm$json$Json$Decode$map3,
		F3(
			function (x, y, z) {
				return {ar: x, as: y, at: z};
			}),
		A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'z', $elm$json$Json$Decode$float));
	var skewVectorDecoder = A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (x, y) {
				return {ar: x, as: y};
			}),
		A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$float),
		A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$float));
	return A6(
		$elm$json$Json$Decode$map5,
		$author$project$Anim$Internal$Engine$WAAPI$SettledValuesPayload,
		A2($elm$json$Json$Decode$field, 'animGroup', $elm$json$Json$Decode$string),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['payload', 'translate']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['payload', 'scale']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['payload', 'rotate']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, vectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])),
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$json$Json$Decode$at,
					_List_fromArray(
						['payload', 'skew']),
					A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, skewVectorDecoder)),
					$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
				])));
}();
var $author$project$Anim$Internal$Property$Opacity$default = 1;
var $author$project$Anim$Internal$Extra$Color$Hsl = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Extra$Color$Hsla = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Extra$Color$Rgb = function (a) {
	return {$: 1, a: a};
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
	var r = rgb_.dy / 255;
	var g = rgb_.c1 / 255;
	var b = rgb_.cR / 255;
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
	return {c2: hNormalized, dc: l * 100, dB: s * 100};
};
var $author$project$Anim$Internal$Extra$Color$rgbaToHsla = function (rgba_) {
	var rgb_ = {cR: rgba_.cR, c1: rgba_.c1, dy: rgba_.dy};
	var hsla_ = $author$project$Anim$Internal$Extra$Color$rgbToHsl(rgb_);
	return {cN: rgba_.cN, c2: hsla_.c2, dc: hsla_.dc, dB: hsla_.dB};
};
var $author$project$Anim$Internal$Extra$Color$toHsl = function (color) {
	switch (color.$) {
		case 3:
			var hsl_ = color.a;
			return hsl_;
		case 4:
			var hslaValue = color.a;
			return {c2: hslaValue.c2, dc: hslaValue.dc, dB: hslaValue.dB};
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
			return {cN: 1.0, c2: hslValue.c2, dc: hslValue.dc, dB: hslValue.dB};
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
	return {cN: alpha_, cR: rgb_.cR, c1: rgb_.c1, dy: rgb_.dy};
};
var $author$project$Anim$Internal$Extra$Color$hslaToRgba = function (hslaValue) {
	var rgb_ = $author$project$Anim$Internal$Extra$Color$hslToRgb(
		{c2: hslaValue.c2, dc: hslaValue.dc, dB: hslaValue.dB});
	return {cN: hslaValue.cN, cR: rgb_.cR, c1: rgb_.c1, dy: rgb_.dy};
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
				cN: rgba_.bK,
				cR: $elm$core$Basics$round(rgba_.cp * 255),
				c1: $elm$core$Basics$round(rgba_.cv * 255),
				dy: $elm$core$Basics$round(rgba_.cF * 255)
			};
		default:
			var rgb_ = $author$project$Anim$Internal$Extra$Color$toRgb(color);
			return {cN: 1.0, cR: rgb_.cR, c1: rgb_.c1, dy: rgb_.dy};
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
							var g = $elm$core$Basics$round(startRgb.c1 + ((endRgb.c1 - startRgb.c1) * t));
							var r = $elm$core$Basics$round(startRgb.dy + ((endRgb.dy - startRgb.dy) * t));
							var b = $elm$core$Basics$round(startRgb.cR + ((endRgb.cR - startRgb.cR) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{cR: b, c1: g, dy: r});
						} else {
							break _v0$5;
						}
					case 1:
						if (_v0.b.$ === 1) {
							var startRgb = _v0.a.a;
							var endRgb = _v0.b.a;
							var r = $elm$core$Basics$round(startRgb.dy + ((endRgb.dy - startRgb.dy) * t));
							var g = $elm$core$Basics$round(startRgb.c1 + ((endRgb.c1 - startRgb.c1) * t));
							var b = $elm$core$Basics$round(startRgb.cR + ((endRgb.cR - startRgb.cR) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{cR: b, c1: g, dy: r});
						} else {
							break _v0$5;
						}
					case 2:
						if (_v0.b.$ === 2) {
							var startRgba = _v0.a.a;
							var endRgba = _v0.b.a;
							var r = $elm$core$Basics$round(startRgba.dy + ((endRgba.dy - startRgba.dy) * t));
							var g = $elm$core$Basics$round(startRgba.c1 + ((endRgba.c1 - startRgba.c1) * t));
							var b = $elm$core$Basics$round(startRgba.cR + ((endRgba.cR - startRgba.cR) * t));
							var a = startRgba.cN + ((endRgba.cN - startRgba.cN) * t);
							return $author$project$Anim$Internal$Extra$Color$Rgba(
								{cN: a, cR: b, c1: g, dy: r});
						} else {
							break _v0$5;
						}
					case 3:
						if (_v0.b.$ === 3) {
							var startHsl = _v0.a.a;
							var endHsl = _v0.b.a;
							var s = startHsl.dB + ((endHsl.dB - startHsl.dB) * t);
							var l = startHsl.dc + ((endHsl.dc - startHsl.dc) * t);
							var h = startHsl.c2 + ((endHsl.c2 - startHsl.c2) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsl(
								{c2: h, dc: l, dB: s});
						} else {
							break _v0$5;
						}
					case 4:
						if (_v0.b.$ === 4) {
							var startHsla = _v0.a.a;
							var endHsla = _v0.b.a;
							var s = startHsla.dB + ((endHsla.dB - startHsla.dB) * t);
							var l = startHsla.dc + ((endHsla.dc - startHsla.dc) * t);
							var h = startHsla.c2 + ((endHsla.c2 - startHsla.c2) * t);
							var a = startHsla.cN + ((endHsla.cN - startHsla.cN) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsla(
								{cN: a, c2: h, dc: l, dB: s});
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
						return rgba_.cN;
					case 4:
						var hsla_ = start.a;
						return hsla_.cN;
					case 5:
						var elmColor_ = start.a;
						var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
						return rgba_.bK;
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
							{cN: startAlpha}));
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
							{cN: startAlpha}));
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
							{cN: startAlpha}));
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
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat = F3(
	function (t, start, end) {
		return start + ((end - start) * t);
	});
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateOpacity = F3(
	function (t, start, end) {
		return $author$project$Anim$Internal$Property$Opacity$fromFloat(
			A3(
				$author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat,
				t,
				$author$project$Anim$Internal$Property$Opacity$toFloat(start),
				$author$project$Anim$Internal$Property$Opacity$toFloat(end)));
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate = F3(
	function (t, start, end) {
		var _v0 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(start);
		var sx = _v0.a;
		var sy = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(end);
		var ex = _v1.a;
		var ey = _v1.b;
		return {ar: sx + ((ex - sx) * t), as: sy + ((ey - sy) * t)};
	});
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate;
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
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateRotate = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Rotate$toTriple, $author$project$Anim$Internal$Property$Rotate$fromTriple);
var $author$project$Anim$Internal$Property$Scale$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateScale = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Scale$toTriple, $author$project$Anim$Internal$Property$Scale$fromTriple);
var $author$project$Anim$Internal$Property$Size$fromTuple = function (_v0) {
	var width = _v0.a;
	var height = _v0.b;
	return {c2: height, R: width};
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
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSize = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Size$toTuple, $author$project$Anim$Internal$Property$Size$fromTuple);
var $author$project$Anim$Internal$Property$Skew$fromTuple = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	return {ar: x, as: y};
};
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSkew = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Skew$toTuple, $author$project$Anim$Internal$Property$Skew$fromTuple);
var $author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTranslate = A2($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Translate$toTriple, $author$project$Anim$Internal$Property$Translate$fromTriple);
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
var $elm_community$easing_functions$Ease$outCirc = function (time) {
	return $elm$core$Basics$sqrt(
		1 - A2($elm$core$Basics$pow, time - 1, 2));
};
var $elm_community$easing_functions$Ease$inCirc = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$inCubic = function (time) {
	return A2($elm$core$Basics$pow, time, 3);
};
var $elm_community$easing_functions$Ease$inExpo = function (time) {
	return (time === 0.0) ? 0.0 : A2($elm$core$Basics$pow, 2, 10 * (time - 1));
};
var $elm_community$easing_functions$Ease$outBack = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inBack);
var $elm_community$easing_functions$Ease$inOutBack = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBack, $elm_community$easing_functions$Ease$outBack);
var $elm_community$easing_functions$Ease$inOutCirc = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCirc, $elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$outCubic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inCubic);
var $elm_community$easing_functions$Ease$inOutCubic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCubic, $elm_community$easing_functions$Ease$outCubic);
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
var $author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT = F2(
	function (cfg, rawProgress) {
		var _v0 = cfg.by;
		if (!_v0.$) {
			var s = _v0.a;
			var motion = {
				bX: 0,
				by: $author$project$Motion$Internal$Spring$unwrap(s),
				cg: 1
			};
			return A2($author$project$Shared$Spring$valueAt, motion, rawProgress * cfg.y);
		} else {
			return A2($author$project$Shared$Easing$toFunction, cfg.bW, rawProgress);
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart = F3(
	function (configStart, baselineCurrent, _default) {
		if (!configStart.$) {
			var value = configStart.a;
			return value;
		} else {
			return A2($elm$core$Maybe$withDefault, _default, baselineCurrent);
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$ProgressApply$applyConfigProgress = F3(
	function (config, rawProgress, baselines) {
		switch (config.$) {
			case 2:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getOpacity(baselines),
					$author$project$Anim$Internal$Property$Opacity$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateOpacity, t, start, cfg.n),
					baselines);
			case 8:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate(baselines),
					$author$project$Anim$Internal$Property$Translate$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateTranslate, t, start, cfg.n),
					baselines);
			case 4:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getRotate(baselines),
					$author$project$Anim$Internal$Property$Rotate$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setRotate,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateRotate, t, start, cfg.n),
					baselines);
			case 5:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getScale(baselines),
					$author$project$Anim$Internal$Property$Scale$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setScale,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateScale, t, start, cfg.n),
					baselines);
			case 7:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getSkew(baselines),
					$author$project$Anim$Internal$Property$Skew$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSkew,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSkew, t, start, cfg.n),
					baselines);
			case 6:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getSize(baselines),
					$author$project$Anim$Internal$Property$Size$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSize,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateSize, t, start, cfg.n),
					baselines);
			case 3:
				var cfg = config.a;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					$author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOrigin(baselines),
					$author$project$Anim$Internal$Property$PerspectiveOrigin$default);
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolatePerspectiveOrigin, t, start, cfg.n),
					baselines);
			case 0:
				var cssName = config.a;
				var unit = config.b;
				var cfg = config.c;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					A2($author$project$Anim$Internal$Builder$PropertyBaselines$getCustomProperty, cssName, baselines),
					0);
				return A4(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty,
					cssName,
					A3($author$project$Anim$Internal$Engine$Shared$Interpolation$interpolateFloat, t, start, cfg.n),
					unit,
					baselines);
			default:
				var cssName = config.a;
				var cfg = config.b;
				var t = A2($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$progressToT, cfg, rawProgress);
				var start = A3(
					$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$resolveStart,
					cfg.bz,
					A2($author$project$Anim$Internal$Builder$PropertyBaselines$getCustomColorProperty, cssName, baselines),
					$author$project$Anim$Internal$Extra$Color$transparent);
				return A3(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty,
					cssName,
					A3($author$project$Anim$Internal$Extra$Color$interpolate, t, start, cfg.n),
					baselines);
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$ProgressApply$applyPropertyProgress = F3(
	function (propertyProgress, propertyStates, baselines) {
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (propType, rawProgress, acc) {
					var _v0 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, propertyStates);
					if (_v0.$ === 1) {
						return acc;
					} else {
						var propState = _v0.a;
						return A3($author$project$Anim$Internal$Engine$WAAPI$ProgressApply$applyConfigProgress, propState.I, rawProgress, acc);
					}
				}),
			baselines,
			propertyProgress);
	});
var $elm$core$Dict$filter = F2(
	function (isGood, dict) {
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (k, v, d) {
					return A2(isGood, k, v) ? A3($elm$core$Dict$insert, k, v, d) : d;
				}),
			$elm$core$Dict$empty,
			dict);
	});
var $author$project$Anim$Internal$Engine$WAAPI$updateAnimGroup = F2(
	function (animUpdate, animGroup) {
		var updateStatus = F2(
			function (propType, propAnim) {
				var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, animUpdate.cE);
				if (_v2.$ === 1) {
					return propAnim;
				} else {
					var currentVersion = _v2.a;
					return _Utils_eq(currentVersion, propAnim.bH) ? _Utils_update(
						propAnim,
						{
							cd: animUpdate.da ? 1 : 3
						}) : propAnim;
				}
			});
		var currentStates = $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates(animGroup);
		var matchingProgress = A2(
			$elm$core$Dict$filter,
			F2(
				function (propType, _v0) {
					var _v1 = _Utils_Tuple2(
						A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, animUpdate.cE),
						A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, propType, currentStates));
					if ((!_v1.a.$) && (!_v1.b.$)) {
						var incomingVersion = _v1.a.a;
						var currentState = _v1.b.a;
						return _Utils_eq(incomingVersion, currentState.bH);
					} else {
						return false;
					}
				}),
			animUpdate.dv);
		return A2(
			$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setSnapshot,
			A3(
				$author$project$Anim$Internal$Engine$WAAPI$ProgressApply$applyPropertyProgress,
				matchingProgress,
				currentStates,
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot(animGroup)),
			A2(
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setPropertyStates,
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, updateStatus, currentStates),
				A2($author$project$Anim$Internal$Engine$WAAPI$AnimGroup$setProgress, animUpdate.X, animGroup)));
	});
var $author$project$Anim$Internal$Engine$WAAPI$update = F2(
	function (msg, animState) {
		var state = animState.a;
		var animGroups = animState.b;
		var jsonValue = msg;
		var _v1 = A2(
			$elm$json$Json$Decode$decodeValue,
			A2($elm$json$Json$Decode$field, 'type', $elm$json$Json$Decode$string),
			jsonValue);
		if (!_v1.$) {
			switch (_v1.a) {
				case 'animationUpdate':
					var engineField = A2(
						$elm$json$Json$Decode$decodeValue,
						A2($elm$json$Json$Decode$field, 'engine', $elm$json$Json$Decode$string),
						jsonValue);
					_v2$2:
					while (true) {
						if (!engineField.$) {
							switch (engineField.a) {
								case 'scrollTimeline':
									return _Utils_Tuple2(animState, $elm$core$Maybe$Nothing);
								case 'viewTimeline':
									return _Utils_Tuple2(animState, $elm$core$Maybe$Nothing);
								default:
									break _v2$2;
							}
						} else {
							break _v2$2;
						}
					}
					var _v3 = A2($elm$json$Json$Decode$decodeValue, $author$project$Anim$Internal$Engine$WAAPI$animEventDecoder, jsonValue);
					if (!_v3.$) {
						var animEvent = _v3.a;
						return _Utils_Tuple2(
							A2($author$project$Anim$Internal$Engine$WAAPI$handleLifecycleEvent, animEvent, animState),
							$elm$core$Maybe$Just(animEvent));
					} else {
						var error = _v3.a;
						return _Utils_Tuple2(
							animState,
							$elm$core$Maybe$Just(
								$author$project$Anim$Internal$Engine$WAAPI$AnimError(
									'Failed to decode animation event: ' + $elm$json$Json$Decode$errorToString(error))));
					}
				case 'propertyUpdate':
					var _v4 = A2($elm$json$Json$Decode$decodeValue, $author$project$Anim$Internal$Engine$WAAPI$animationUpdateDecoder, jsonValue);
					if (!_v4.$) {
						var animUpdate = _v4.a;
						var updatedAnimations = A3(
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$update,
							animUpdate.aB,
							$elm$core$Maybe$map(
								$author$project$Anim$Internal$Engine$WAAPI$updateAnimGroup(animUpdate)),
							animGroups);
						var shouldEmitProgress = A2($author$project$Anim$Internal$Builder$getEmitProgressFor, animUpdate.aB, state.q);
						var progressEvent = shouldEmitProgress ? $elm$core$Maybe$Just(
							A2($author$project$Anim$Internal$Engine$WAAPI$Progress, animUpdate.aB, animUpdate.X)) : $elm$core$Maybe$Nothing;
						var hasRunningAnimations = A2(
							$elm$core$List$any,
							A2(
								$elm$core$Basics$composeR,
								$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups,
									$elm$core$List$any(
										function (prop) {
											return prop.cd === 1;
										}))),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(updatedAnimations));
						return _Utils_Tuple2(
							A2(
								$author$project$Anim$Internal$Engine$WAAPI$AnimState,
								_Utils_update(
									state,
									{_: hasRunningAnimations}),
								updatedAnimations),
							progressEvent);
					} else {
						var error = _v4.a;
						return _Utils_Tuple2(
							animState,
							$elm$core$Maybe$Just(
								$author$project$Anim$Internal$Engine$WAAPI$AnimError(
									'Failed to decode animation update: ' + $elm$json$Json$Decode$errorToString(error))));
					}
				case 'settledValues':
					var _v5 = A2($elm$json$Json$Decode$decodeValue, $author$project$Anim$Internal$Engine$WAAPI$settledValuesDecoder, jsonValue);
					if (!_v5.$) {
						var settledValues = _v5.a;
						return _Utils_Tuple2(
							A2($author$project$Anim$Internal$Engine$WAAPI$handleSettledValues, settledValues, animState),
							$elm$core$Maybe$Nothing);
					} else {
						var error = _v5.a;
						return _Utils_Tuple2(
							animState,
							$elm$core$Maybe$Just(
								$author$project$Anim$Internal$Engine$WAAPI$AnimError(
									'Failed to decode settled values: ' + $elm$json$Json$Decode$errorToString(error))));
					}
				case 'frozenAxesApplied':
					var _v6 = A2($elm$json$Json$Decode$decodeValue, $author$project$Anim$Internal$Engine$WAAPI$frozenAxesDecoder, jsonValue);
					if (!_v6.$) {
						var frozenAxes = _v6.a;
						return _Utils_Tuple2(
							A2($author$project$Anim$Internal$Engine$WAAPI$handleFrozenAxesAcknowledgment, frozenAxes, animState),
							$elm$core$Maybe$Nothing);
					} else {
						var error = _v6.a;
						return _Utils_Tuple2(
							animState,
							$elm$core$Maybe$Just(
								$author$project$Anim$Internal$Engine$WAAPI$AnimError(
									'Failed to decode frozen axes: ' + $elm$json$Json$Decode$errorToString(error))));
					}
				default:
					var unknown = _v1.a;
					return _Utils_Tuple2(
						animState,
						$elm$core$Maybe$Just(
							$author$project$Anim$Internal$Engine$WAAPI$AnimError('Unknown message type: ' + unknown)));
			}
		} else {
			var error = _v1.a;
			return _Utils_Tuple2(
				animState,
				$elm$core$Maybe$Just(
					$author$project$Anim$Internal$Engine$WAAPI$AnimError(
						'Unknown message type: ' + $elm$json$Json$Decode$errorToString(error))));
		}
	});
var $author$project$Anim$Engine$WAAPI$update = function (msg) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$WAAPI$update(msg),
		$elm$core$Tuple$mapSecond(
			$elm$core$Maybe$map($author$project$Anim$Engine$WAAPI$toAnimEvent)));
};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 6:
				var subMsg = msg.a;
				var _v1 = A2($author$project$Anim$Engine$WAAPI$update, subMsg, model.D);
				var newAnimState = _v1.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					$elm$core$Platform$Cmd$none);
			case 0:
				var _v2 = A2(
					$author$project$Anim$Engine$WAAPI$animate,
					model.D,
					A2(
						$elm$core$Basics$composeR,
						$author$project$Anim$Engine$WAAPI$for($author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup),
						$author$project$Animation$WAAPI$ControllingAnimations$Main$dropBall));
				var newAnimState = _v2.a;
				var animCmd = _v2.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					animCmd);
			case 1:
				var _v3 = A2($author$project$Anim$Engine$WAAPI$stop, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, model.D);
				var newAnimState = _v3.a;
				var stopCmd = _v3.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					stopCmd);
			case 2:
				var _v4 = A2($author$project$Anim$Engine$WAAPI$pause, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, model.D);
				var newAnimState = _v4.a;
				var pauseCmd = _v4.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					pauseCmd);
			case 3:
				var _v5 = A2($author$project$Anim$Engine$WAAPI$resume, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, model.D);
				var newAnimState = _v5.a;
				var resumeCmd = _v5.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					resumeCmd);
			case 4:
				var _v6 = A2($author$project$Anim$Engine$WAAPI$reset, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, model.D);
				var newAnimState = _v6.a;
				var resetCmd = _v6.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					resetCmd);
			default:
				var _v7 = A2($author$project$Anim$Engine$WAAPI$restart, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, model.D);
				var newAnimState = _v7.a;
				var restartCmd = _v7.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{D: newAnimState}),
					restartCmd);
		}
	});
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Animate = {$: 0};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Pause = {$: 2};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Reset = {$: 4};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Restart = {$: 5};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Resume = {$: 3};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$Stop = {$: 1};
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $elm$virtual_dom$VirtualDom$attribute = F2(
	function (key, value) {
		return A2(
			_VirtualDom_attribute,
			_VirtualDom_noOnOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $elm$html$Html$Attributes$attribute = $elm$virtual_dom$VirtualDom$attribute;
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Anim$Internal$Property$Rotate$toCssString = function (_v0) {
	var angles = _v0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(!(!angles.ar)) ? $elm$core$Maybe$Just(
				'rotateX(' + ($elm$core$String$fromFloat(angles.ar) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.as)) ? $elm$core$Maybe$Just(
				'rotateY(' + ($elm$core$String$fromFloat(angles.as) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.at)) ? $elm$core$Maybe$Just(
				'rotateZ(' + ($elm$core$String$fromFloat(angles.at) + 'deg)')) : $elm$core$Maybe$Nothing
			]));
	return $elm$core$List$isEmpty(parts) ? 'rotateZ(0deg)' : A2($elm$core$String$join, ' ', parts);
};
var $author$project$Anim$Internal$Property$Scale$toCssString = function (_v0) {
	var z = _v0.at;
	var y = _v0.as;
	var x = _v0.ar;
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
				(!(!values.ar)) ? $elm$core$Maybe$Just(
				'skewX(' + ($elm$core$String$fromFloat(values.ar) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!values.as)) ? $elm$core$Maybe$Just(
				'skewY(' + ($elm$core$String$fromFloat(values.as) + 'deg)')) : $elm$core$Maybe$Nothing
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
var $author$project$Anim$Internal$Property$Translate$toCssString = F2(
	function (axes, _v0) {
		var coords = _v0;
		return 'translate3d(' + ($elm$core$String$fromFloat(coords.ar) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.ar) + (', ' + ($elm$core$String$fromFloat(coords.as) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.as) + (', ' + ($elm$core$String$fromFloat(coords.at) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.at) + ')'))))))));
	});
var $author$project$Anim$Internal$Engine$WAAPI$transformOrderToPart = F5(
	function (translatePart, rotatePart, skewPart, scalePart, order) {
		switch (order) {
			case 0:
				return translatePart;
			case 1:
				return rotatePart;
			case 2:
				return skewPart;
			default:
				return scalePart;
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$buildTransformStyles = F3(
	function (order, snapshot, translateLength) {
		var translatePart = A2(
			$elm$core$Maybe$withDefault,
			'',
			A2(
				$elm$core$Maybe$map,
				$author$project$Anim$Internal$Property$Translate$toCssString(translateLength),
				$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate(snapshot)));
		var skewPart = A2(
			$elm$core$Maybe$withDefault,
			'',
			A2(
				$elm$core$Maybe$map,
				$author$project$Anim$Internal$Property$Skew$toCssString,
				$author$project$Anim$Internal$Builder$PropertyBaselines$getSkew(snapshot)));
		var scalePart = A2(
			$elm$core$Maybe$withDefault,
			'',
			A2(
				$elm$core$Maybe$map,
				$author$project$Anim$Internal$Property$Scale$toCssString,
				$author$project$Anim$Internal$Builder$PropertyBaselines$getScale(snapshot)));
		var rotatePart = A2(
			$elm$core$Maybe$withDefault,
			'',
			A2(
				$elm$core$Maybe$map,
				$author$project$Anim$Internal$Property$Rotate$toCssString,
				$author$project$Anim$Internal$Builder$PropertyBaselines$getRotate(snapshot)));
		var transformString = A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$filter,
				A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$String$isEmpty),
				A2(
					$elm$core$List$map,
					A4($author$project$Anim$Internal$Engine$WAAPI$transformOrderToPart, translatePart, rotatePart, skewPart, scalePart),
					order)));
		return $elm$core$String$isEmpty(transformString) ? _List_Nil : _List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'transform', transformString)
			]);
	});
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getDiscreteEntry = function (_v0) {
	var group = _v0;
	return group.cr;
};
var $author$project$Anim$Internal$Engine$WAAPI$discreteEntryStyles = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getDiscreteEntry,
	A2(
		$elm$core$Basics$composeR,
		$elm$core$Dict$toList,
		$elm$core$List$map(
			function (_v0) {
				var prop = _v0.a;
				var value = _v0.b;
				return A2($elm$html$Html$Attributes$style, prop, value);
			})));
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getDiscreteExit = function (_v0) {
	var group = _v0;
	return group.cs;
};
var $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$isComplete = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups,
		$elm$core$List$all(
			function (prop) {
				return prop.cd === 3;
			})));
var $author$project$Anim$Internal$Engine$WAAPI$discreteExitStyles = function (animGroup) {
	return A2(
		$elm$core$List$map,
		function (_v0) {
			var prop = _v0.a;
			var to = _v0.b.cg;
			var from = _v0.b.bX;
			return $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$isComplete(animGroup) ? A2($elm$html$Html$Attributes$style, prop, to) : A2($elm$html$Html$Attributes$style, prop, from);
		},
		$elm$core$Dict$toList(
			$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getDiscreteExit(animGroup)));
};
var $author$project$Anim$Internal$Builder$getAnimationConfigs = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.x.aC);
		if (_v1.$ === 1) {
			return _List_Nil;
		} else {
			var h = _v1.a;
			return A2(
				$elm$core$List$map,
				function ($) {
					return $.I;
				},
				A2($elm$core$List$cons, h.aG, h.bi));
		}
	});
var $author$project$Anim$Internal$Engine$WAAPI$findCurrentTranslate = F2(
	function (animGroupName, builder) {
		return $elm$core$List$head(
			A2(
				$elm$core$List$filterMap,
				function (group) {
					return $elm$core$List$head(
						A2(
							$elm$core$List$filterMap,
							function (p) {
								if (p.$ === 8) {
									var cfg = p.a;
									return $elm$core$Maybe$Just(cfg);
								} else {
									return $elm$core$Maybe$Nothing;
								}
							},
							group.s));
				},
				A2($author$project$Anim$Internal$Builder$getAnimationConfigs, animGroupName, builder)));
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$getAllCustomColorProperties = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$List$filterMap,
		function (_v1) {
			var key = _v1.a;
			var value = _v1.b;
			if (value.$ === 1) {
				var color = value.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						A2($elm$core$String$dropLeft, 12, key),
						color));
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		$elm$core$Dict$toList(dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getAllCustomProperties = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$List$filterMap,
		function (_v1) {
			var key = _v1.a;
			var value = _v1.b;
			if (!value.$) {
				var f = value.a;
				var unit = value.b;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						A2($elm$core$String$dropLeft, 7, key),
						_Utils_ap(
							$elm$core$String$fromFloat(f),
							unit)));
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		$elm$core$Dict$toList(dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOriginUnits = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 4) {
				var u = v.a;
				return $elm$core$Maybe$Just(u);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'perspectiveOriginUnits', dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getSizeUnits = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 9) {
				var u = v.a;
				return $elm$core$Maybe$Just(u);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'sizeUnits', dict));
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslateUnits = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 13) {
				var u = v.a;
				return $elm$core$Maybe$Just(u);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'translateUnits', dict));
};
var $author$project$Anim$Internal$Property$Size$heightToCssString = F2(
	function (axes, _v0) {
		var dimensions = _v0;
		return _Utils_ap(
			$elm$core$String$fromFloat(dimensions.c2),
			$author$project$Anim$Internal$Unit$toCssSuffix(axes.as));
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$member = F2(
	function (name, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$member, name, dict);
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString = F2(
	function (axes, _v0) {
		var y = _v0.as;
		var x = _v0.ar;
		return $elm$core$String$fromFloat(x) + ($author$project$Anim$Internal$Unit$toCssSuffix(axes.ar) + (' ' + ($elm$core$String$fromFloat(y) + $author$project$Anim$Internal$Unit$toCssSuffix(axes.as))));
	});
var $author$project$Anim$Internal$Property$Opacity$toString = function (_v0) {
	var o = _v0;
	return $elm$core$String$fromFloat(o);
};
var $author$project$Anim$Internal$Property$Size$widthToCssString = F2(
	function (axes, _v0) {
		var dimensions = _v0;
		return _Utils_ap(
			$elm$core$String$fromFloat(dimensions.R),
			$author$project$Anim$Internal$Unit$toCssSuffix(axes.ar));
	});
var $author$project$Anim$Internal$Engine$WAAPI$attributes = F2(
	function (animGroupName, _v0) {
		var state = _v0.a;
		var data = _v0.b;
		var dataAttr = A2($elm$html$Html$Attributes$attribute, 'data-anim-target', animGroupName);
		var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data);
		if (_v1.$ === 1) {
			return _List_fromArray(
				[dataAttr]);
		} else {
			var animGroup = _v1.a;
			var snapshot = $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertySnapshot(animGroup);
			var propertyStates = $author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getPropertyStates(animGroup);
			var isElmOwned = function (propType) {
				return !A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$member, propType, propertyStates);
			};
			var simpleStyles = A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						isElmOwned('opacity') ? A2(
						$elm$core$Maybe$map,
						function (o) {
							return A2(
								$elm$html$Html$Attributes$style,
								'opacity',
								$author$project$Anim$Internal$Property$Opacity$toString(o));
						},
						$author$project$Anim$Internal$Builder$PropertyBaselines$getOpacity(snapshot)) : $elm$core$Maybe$Nothing,
						isElmOwned('perspectiveOrigin') ? A2(
						$elm$core$Maybe$map,
						function (po) {
							return A2(
								$elm$html$Html$Attributes$style,
								'perspective-origin',
								A2(
									$author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString,
									A2(
										$elm$core$Maybe$withDefault,
										{ar: 28, as: 28, at: 28},
										$author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOriginUnits(snapshot)),
									po));
						},
						$author$project$Anim$Internal$Builder$PropertyBaselines$getPerspectiveOrigin(snapshot)) : $elm$core$Maybe$Nothing
					]));
			var sizeStyles = isElmOwned('size') ? A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2(
					$elm$core$Maybe$map,
					function (s) {
						var sizeUnits = A2(
							$elm$core$Maybe$withDefault,
							{ar: $author$project$Anim$Internal$Unit$default, as: $author$project$Anim$Internal$Unit$default, at: $author$project$Anim$Internal$Unit$default},
							$author$project$Anim$Internal$Builder$PropertyBaselines$getSizeUnits(snapshot));
						return _List_fromArray(
							[
								A2(
								$elm$html$Html$Attributes$style,
								'width',
								A2($author$project$Anim$Internal$Property$Size$widthToCssString, sizeUnits, s)),
								A2(
								$elm$html$Html$Attributes$style,
								'height',
								A2($author$project$Anim$Internal$Property$Size$heightToCssString, sizeUnits, s))
							]);
					},
					$author$project$Anim$Internal$Builder$PropertyBaselines$getSize(snapshot))) : _List_Nil;
			var transformIsElmOwned = A2(
				$elm$core$List$all,
				isElmOwned,
				_List_fromArray(
					['translate', 'rotate', 'skew', 'scale']));
			var transformStyles = transformIsElmOwned ? A3(
				$author$project$Anim$Internal$Engine$WAAPI$buildTransformStyles,
				$author$project$Anim$Internal$Engine$WAAPI$AnimGroup$getTransformOrder(animGroup),
				snapshot,
				A2(
					$elm$core$Maybe$withDefault,
					A2(
						$elm$core$Maybe$withDefault,
						{ar: $author$project$Anim$Internal$Unit$default, as: $author$project$Anim$Internal$Unit$default, at: $author$project$Anim$Internal$Unit$default},
						A2(
							$elm$core$Maybe$map,
							function ($) {
								return $.E;
							},
							A2($author$project$Anim$Internal$Engine$WAAPI$findCurrentTranslate, animGroupName, state.q))),
					$author$project$Anim$Internal$Builder$PropertyBaselines$getTranslateUnits(snapshot))) : _List_Nil;
			var customPropertyStyles = A2(
				$elm$core$List$map,
				function (_v5) {
					var name = _v5.a;
					var cssValue = _v5.b;
					return A2($elm$html$Html$Attributes$style, name, cssValue);
				},
				A2(
					$elm$core$List$filter,
					function (_v4) {
						var name = _v4.a;
						return isElmOwned('custom:' + name);
					},
					$author$project$Anim$Internal$Builder$PropertyBaselines$getAllCustomProperties(snapshot)));
			var customColorPropertyStyles = A2(
				$elm$core$List$map,
				function (_v3) {
					var name = _v3.a;
					var color = _v3.b;
					return A2(
						$elm$html$Html$Attributes$style,
						name,
						$author$project$Anim$Internal$Extra$Color$toCssString(color));
				},
				A2(
					$elm$core$List$filter,
					function (_v2) {
						var name = _v2.a;
						return isElmOwned('customColor:' + name);
					},
					$author$project$Anim$Internal$Builder$PropertyBaselines$getAllCustomColorProperties(snapshot)));
			return A2(
				$elm$core$List$cons,
				dataAttr,
				_Utils_ap(
					transformStyles,
					_Utils_ap(
						simpleStyles,
						_Utils_ap(
							sizeStyles,
							_Utils_ap(
								customPropertyStyles,
								_Utils_ap(
									customColorPropertyStyles,
									_Utils_ap(
										$author$project$Anim$Internal$Engine$WAAPI$discreteEntryStyles(animGroup),
										$author$project$Anim$Internal$Engine$WAAPI$discreteExitStyles(animGroup))))))));
		}
	});
var $author$project$Anim$Engine$WAAPI$attributes = $author$project$Anim$Internal$Engine$WAAPI$attributes;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSizeCqh = $elm$core$String$fromFloat($author$project$Animation$WAAPI$ControllingAnimations$Main$ballSize) + 'cqh';
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Animation$WAAPI$ControllingAnimations$Main$animationArea = function (animState) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('example-canvas--fluid'),
				A2($elm$html$Html$Attributes$style, 'border-bottom', '2px solid #333'),
				A2($elm$html$Html$Attributes$style, 'container-type', 'size')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_Utils_ap(
					A2($author$project$Anim$Engine$WAAPI$attributes, $author$project$Animation$WAAPI$ControllingAnimations$Main$animGroup, animState),
					_List_fromArray(
						[
							A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							'calc(50% - ' + ($elm$core$String$fromFloat($author$project$Animation$WAAPI$ControllingAnimations$Main$ballSize / 2) + 'cqh)')),
							A2($elm$html$Html$Attributes$style, 'width', $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSizeCqh),
							A2($elm$html$Html$Attributes$style, 'height', $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSizeCqh),
							A2($elm$html$Html$Attributes$style, 'font-size', $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSizeCqh),
							A2($elm$html$Html$Attributes$style, 'line-height', $author$project$Animation$WAAPI$ControllingAnimations$Main$ballSizeCqh)
						])),
				_List_fromArray(
					[
						$elm$html$Html$text('🏀')
					]))
			]));
};
var $elm$html$Html$button = _VirtualDom_node('button');
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$view = function (model) {
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
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('example-controls')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Animate),
								$elm$html$Html$Attributes$class('ui-action-button primary')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('🏀 Animate')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Pause),
								$elm$html$Html$Attributes$class('ui-action-button success')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('⏸️ Pause')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Resume),
								$elm$html$Html$Attributes$class('ui-action-button success')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('▶️ Resume')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Stop),
								$elm$html$Html$Attributes$class('ui-action-button warning')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('⏹️ Stop')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Reset),
								$elm$html$Html$Attributes$class('ui-action-button purple')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('⏮️ Reset')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick($author$project$Animation$WAAPI$ControllingAnimations$Main$Restart),
								$elm$html$Html$Attributes$class('ui-action-button purple')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('🔄 Restart')
							]))
					])),
				$author$project$Animation$WAAPI$ControllingAnimations$Main$animationArea(model.D)
			]));
};
var $author$project$Animation$WAAPI$ControllingAnimations$Main$main = $elm$browser$Browser$element(
	{
		eY: function (_v0) {
			return $author$project$Animation$WAAPI$ControllingAnimations$Main$init;
		},
		fN: $author$project$Animation$WAAPI$ControllingAnimations$Main$subscriptions,
		gb: $author$project$Animation$WAAPI$ControllingAnimations$Main$update,
		gc: $author$project$Animation$WAAPI$ControllingAnimations$Main$view
	});
_Platform_export({'Animation':{'WAAPI':{'ControllingAnimations':{'Main':{'init':$author$project$Animation$WAAPI$ControllingAnimations$Main$main(
	$elm$json$Json$Decode$succeed(0))(0)}}}}});}(this));