import turtle
wn = turtle.Screen()
wn.bgcolor("lightgreen")
david = turtle.Turtle()
david.color("blue")
david.pensize(10)
david.shape("turtle")
for hour in range(12):
	david.penup()
	david.forward(200)
	david.pendown()	
	david.forward(30)
	david.penup()
	david.forward(30)
	david.stamp()
	david.penup()
	david.backward(260)
	david.right(30)
wn.exitonclick()
