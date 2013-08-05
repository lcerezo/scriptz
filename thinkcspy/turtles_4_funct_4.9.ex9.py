import turtle

def draw_square(t, sz):
        for side in range(4):
                t.pendown()
                t.forward(sz)
                t.left(90)
                t.penup()

def draw_poly(t, n, sz):
	"""
	draw a polygon of
		t = name of turtle
		n = number of sides/gons
		sz = length of the side
	"""
	for side in range(n):
		angle = (360/n)
		t.pendown()
		t.forward(sz)
		t.right(angle)	

def draw_spiral(t, ang, turns):
	for side in range(turns):
		side = side + 5
		t.forward(side)
		t.left(ang)
def draw_equitriangle(t, sz):
	draw_poly(t, 3, sz)

def sum_to(n):
	num = 0
	n = n + 1
	for x in range(n):
		num = num + x
	print(num)

def area_of_circle(r):
	pi = 22/7
	area = (pi * r * r)
	print(area)

def draw_star(t, sz):
	for side in range(5):
		t.pendown()
		t.forward(sz)
		t.left(144)
		t.penup()

def setup_turtle(sz, colr):
		t = turtle.Turtle()
		t.color(colr)
		t.pensize(sz)
		return t	

def make_window(colr, tits):
		w = turtle.Screen()
		w.bgcolor(colr)
		w.title(tits)
		return w
wn = make_window("lightgreen", "stuffs")
dood = setup_turtle(3, "hotpink")
draw_star(dood, 100)
wn.mainloop()
