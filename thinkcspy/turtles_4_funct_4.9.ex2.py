import turtle

def draw_square(t, sz):
	for side in range(4):
		t.pendown()
		t.forward(sz)
		t.left(90)
		t.penup()


wn = turtle.Screen()
wn.bgcolor("lightgreen")
wn.title("Alex meets a funk-shun")


teddy = turtle.Turtle()
sIze = 66
for sq in range(5):
	sIze = sIze + 20
	draw_square(teddy, sIze)
	teddy.penup()
	teddy.backward(10)
	teddy.right(90)
	teddy.forward(10)
	teddy.pendown()
	teddy.left(90)

wn.mainloop()
