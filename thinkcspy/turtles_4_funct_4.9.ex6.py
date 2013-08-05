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

wn = turtle.Screen()
wn.bgcolor("lightgreen")
wn.title("Alex meets a funk-shun")


teddy = turtle.Turtle()
teddy.pensize(1)
draw_equitriangle(teddy, 90)

wn.mainloop()
