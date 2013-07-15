import turtle
wn = turtle.Screen()
wn.bgcolor("lightgreen")
david = turtle.Turtle()
david.color("blue")
david.pensize(10)
for d in range(5):
	david.forward(400)
	david.right(144)

wn.exitonclick()
