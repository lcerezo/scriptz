import sys

def test(did_pass):
    """  Print the result of a test.  """
    linenum = sys._getframe(1).f_lineno   # Get the caller's line number.
    if did_pass:
        msg = "Test at line {0} ok.".format(linenum)
    else:
        msg = ("Test at line {0} FAILED.".format(linenum))
    print(msg)
    
def test_suite():
    """ Run the suite of tests for code in this module (this file).
    """
    test(absolute_value(17) == 17)
    test(absolute_value(-17) == 17)
    test(absolute_value(0) == 0)
    test(absolute_value(3.14) == 3.14)
    test(absolute_value(-3.14) == 3.14)

def turn_clockwise(d):
		if  d == "N":
			new_dir = "E"
		elif d == "E":
			new_dir = "S"
		elif d == "S":
			new_dir = "W"
		elif d == "W":
			new_dir = "N"
		return new_dir
	
	
test(turn_clockwise("S") == "E")
test(turn_clockwise("W") == "N")
