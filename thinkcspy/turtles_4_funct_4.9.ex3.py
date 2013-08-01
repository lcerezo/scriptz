import turtle

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
draw_poly(teddy, 8, 50)
wn.mainloop()
