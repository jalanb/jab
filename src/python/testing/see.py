#!/usr/bin/env python

"""
see
A human alternative to dir().

	>>> from see import see
	>>> help(see)
	Help on function see in module see:
	...

Copyright (c) 2009-2010 Liam Cooke
http://inky.github.com/see/

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY LIAM COOKE "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

"""

# pylint: disable-msg=W0141, R0912


import re
import os
import sys
import textwrap
import fnmatch
import inspect


from pprint import pformat

__all__ = ['see']

__author__ = 'Liam Cooke'
__contributors__ = [
	'Bob Farrell',
	'Gabriel Genellina',
	'Baishampayan Ghose',
	'Charlie Nolan',
	'Ed Page',
	'guff',
	'jdunck',
	'Steve Losh',
	'Adam Lloyd',
]
__version__ = '1.0.1'
__copyright__ = 'Copyright (c) 2009-2010 Liam Cooke'
__license__ = 'BSD License'


def regex_filter(names, pat):
	pat = re.compile(pat)

	def match(name, fn=pat.search):
		return fn(name) is not None
	return tuple(filter(match, names))


def fn_filter(names, pat):

	def match(name, fn=fnmatch.fnmatch, pat=pat):
		return fn(name, pat)
	return tuple(filter(match, names))


class SeeError(Exception): pass


class _SeeOutput(tuple):
	"""Tuple-like object with a pretty string representation."""

	def __new__(cls, actions=None):
		return tuple.__new__(cls, actions or [])

	def __repr__(self):
		lens = sorted(map(len, self)) or [0]
		max_len = lens[-1]

		def justify(item):
			if len(item) <= max_len + 2:
				return item.ljust(max_len + 4)
			else:
				return item.ljust(max_len * 2 + 8)

		padded = [justify(i) for i in self]
		if 'ps1' in dir(sys):
			indent = ' ' * len(sys.ps1)
		else:
			indent = '	'
		columns = int(os.environ.get('COLUMNS', 80)) - 5
		return textwrap.fill(''.join(padded), columns, initial_indent=indent, subsequent_indent=indent)


class _SeeDefault(object):
	def __repr__(self):
		return 'anything'

_LOCALS = _SeeDefault()


def see(obj=_LOCALS, pattern=None, r=None, methods=None, attributes=None):
	"""
	Inspect an object. Like the dir() builtin, but easier on the eyes.

	Keyword arguments (all optional):
	obj -- object to be inspected
	pattern -- shell-style search pattern (e.g. '*len*')
	r -- regular expression

	If obj is omitted, objects in the current scope are listed instead.

	Some unique symbols are used:

		.*	  implements obj.anything
		[]	  implements obj[key]
		in	  implements membership tests (e.g. x in obj)
		+obj	unary positive operator (e.g. +2)
		-obj	unary negative operator (e.g. -2)
		?	   raised an exception

	"""
	use_locals = obj is _LOCALS
	actions = []
	dot = not use_locals and '.' or ''
	name = lambda a, f: ''.join((dot, a, suffix(f)))
	if methods is None and attributes is None:
		methods = attributes = True

	def suffix(f):
		if isinstance(f, SeeError):
			return '?'
		elif hasattr(f, '__call__'):
			return '()'
		else:
			return ''

	if use_locals:
		obj.__dict__ = inspect.currentframe().f_back.f_locals
	attrs = dir(obj)
	if not use_locals:
		for var, symbol in SYMBOLS:
			if var not in attrs or symbol in actions:
				continue
			elif var == '__doc__':
				if not obj.__doc__ or not obj.__doc__.strip():
					continue
			actions.append(symbol)

	for attr in filter(lambda a: not a.startswith('_'), attrs):
		try:
			prop = getattr(obj, attr)
			if callable(prop):
				if not methods:
					continue
			else:
				if not attributes:
					continue
		except (AttributeError, Exception):
			prop = SeeError()
		actions.append(name(attr, prop))

	if pattern is not None:
		actions = fn_filter(actions, pattern)
	if r is not None:
		actions = regex_filter(actions, r)

	return _SeeOutput(actions)


def see_methods(*args, **kwargs):
	kwargs['methods'] = True
	return see(*args, **kwargs)


def see_attributes(*args, **kwargs):
	kwargs['attributes'] = True
	return see(*args, **kwargs)


def spread(thing, exclude = None):
	'''Spread out the attributes of thing onto stdout

	exclude is a list of regular expressions
		attributes matching any if these will not be shown
		if the default of None is used it is set to ['__.*__']
	'''
	ids = []
	if not exclude:
		exclude = ['__.*__']
	exclusions = [re.compile(e) for e in exclude]

	def spread_out_an_attribute(v, separator):
		if not v:
			return repr(v)
		if id(v) in ids:
			return str(v)
		return spread_out_the_attributes(v, separator)

	def spread_out_the_attributes(thing, separator):
		if not thing or not hasattr(thing, '__dict__'):
			return pformat(thing)
		ids.append(id(thing))
		attributes_list = []
		for k, v in thing.__dict__.iteritems():
			if isinstance(v, type(sys)):
				continue
			if callable(v):
				continue
			excluded = False
			for exclusion in exclusions:
				if exclusion.search(k):
					excluded = True
					break
			if excluded:
				continue
			if hasattr(v, '__repr__'):
				value = v.__repr__()
			else:
				value = spread_out_an_attribute(v, separator)
			lines = separator.join(value.splitlines())
			attributes_list.append('%s : %s' % (k, lines))
		attributes_string = separator.join(attributes_list)
		ids.pop()
		klass = hasattr(thing, '__class__') and thing.__class__.__name__ or dir(thing)
		return '''<%s%s%s\n%s>''' % (klass, separator, attributes_string, separator[1:-2])

	print spread_out_the_attributes(thing, '\n\t')


PY_300 = sys.version_info >= (3, 0)
PY_301 = sys.version_info >= (3, 0, 1)


SYMBOLS = tuple(filter(lambda x: x[0], (
	# callable
	('__call__', '()'),

	# element/attribute access
	('__getattr__', '.*'),
	('__getitem__', '[]'),
	('__setitem__', '[]'),
	('__delitem__', '[]'),

	# iteration
	('__enter__', 'with'),
	('__exit__', 'with'),
	('__contains__', 'in'),

	# operators
	('__add__', '+'),
	('__radd__', '+'),
	('__iadd__', '+='),
	('__sub__', '-'),
	('__rsub__', '-'),
	('__isub__', '-='),
	('__mul__', '*'),
	('__rmul__', '*'),
	('__imul__', '*='),
	(not PY_300 and '__div__', '/'),
	(not PY_301 and '__rdiv__', '/'),
	('__truediv__', '/'),
	('__rtruediv__', '/'),
	('__floordiv__', '//'),
	('__rfloordiv__', '//'),
	(not PY_300 and '__idiv__', '/='),
	('__itruediv__', '/='),
	('__ifloordiv__', '//='),
	('__mod__', '%'),
	('__rmod__', '%'),
	('__divmod__', '%'),
	('__imod__', '%='),
	('__pow__', '**'),
	('__rpow__', '**'),
	('__ipow__', '**='),
	('__lshift__', '<<'),
	('__rlshift__', '<<'),
	('__ilshift__', '<<='),
	('__rshift__', '>>'),
	('__rrshift__', '>>'),
	('__irshift__', '>>='),
	('__and__', '&'),
	('__rand__', '&'),
	('__iand__', '&='),
	('__xor__', '^'),
	('__rxor__', '^'),
	('__ixor__', '^='),
	('__or__', '|'),
	('__ror__', '|'),
	('__ior__', '|='),
	('__pos__', '+obj'),
	('__neg__', '-obj'),
	('__invert__', '~'),
	('__lt__', '<'),
	(not PY_301 and '__cmp__', '<'),
	('__le__', '<='),
	(not PY_301 and '__cmp__', '<='),
	('__eq__', '=='),
	(not PY_301 and '__cmp__', '=='),
	('__ne__', '!='),
	(not PY_301 and '__cmp__', '!='),
	('__gt__', '>'),
	(not PY_301 and '__cmp__', '>'),
	('__ge__', '>='),
	(not PY_301 and '__cmp__', '>='),

	# built-in functions
	('__abs__', 'abs()'),
	(PY_300 and '__bool__' or '__nonzero__', 'bool()'),
	('__complex__', 'complex()'),
	(PY_300 and '__dir__', 'dir()'),
	('__divmod__', 'divmod()'),
	('__rdivmod__', 'divmod()'),
	('__float__', 'float()'),
	('__hash__', 'hash()'),
	('__doc__', 'help()'),
	(PY_300 and '__index__' or '__hex__', 'hex()'),
	('__int__', 'int()'),
	('__iter__', 'iter()'),
	('__len__', 'len()'),
	(not PY_300 and '__long__', 'long()'),
	(PY_300 and '__index__' or '__oct__', 'oct()'),
	('__repr__', 'repr()'),
	('__reversed__', 'reversed()'),
	(PY_300 and '__round__', 'round()'),
	('__str__', 'str()'),
	(PY_300 and '__unicode__', 'unicode()'),
)))


if __name__ == '__main__':
	help(see)

# vim: expandtab tabstop=4 shiftround shiftwidth=4 fdm=marker