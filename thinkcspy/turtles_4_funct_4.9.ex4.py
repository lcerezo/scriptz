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


wn = turtle.Screen()
wn.bgcolor("lightgreen")
wn.title("Alex meets a funk-shun")


teddy = turtle.Turtle()
teddy.pensize(3)
for x in range(21):
	draw_square(teddy, 110)
	teddy.right(360/21)
wn.mainloop()
