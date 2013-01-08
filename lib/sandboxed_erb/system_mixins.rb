=begin

This file is part of the sandboxed_erb project, https://github.com/markpent/SandboxedERB

Copyright (c) 2011 Mark Pentland <mark.pent@gmail.com>

sandboxed_erb is free software: you can redistribute it and/or modify
it under the terms of the gnu general public license as published by
the free software foundation, either version 3 of the license, or
(at your option) any later version.

sandboxed_erb is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.  see the
gnu general public license for more details.

you should have received a copy of the gnu general public license
along with shikashi.  if not, see <http://www.gnu.org/licenses/>.

=end


#add sandboxed method to basic inbuilt objects
String.not_sandboxed_methods true, [Comparable, Enumerable], :bang_methods
Fixnum.not_sandboxed_methods true, [Comparable], :bang_methods
Float.not_sandboxed_methods true, [Comparable], :bang_methods
Range.not_sandboxed_methods true, [Enumerable], :bang_methods
Symbol.not_sandboxed_methods true
Time.not_sandboxed_methods true, [Comparable], :bang_methods
Date.not_sandboxed_methods true, [Comparable], :bang_methods
DateTime.not_sandboxed_methods true, [Comparable], :bang_methods
NilClass.not_sandboxed_methods true
Array.not_sandboxed_methods true, [Enumerable], :bang_methods
Hash.not_sandboxed_methods true, [Enumerable], :bang_methods
FalseClass.not_sandboxed_methods true
TrueClass.not_sandboxed_methods true
