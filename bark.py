print("tellme: how much barking to be added: ", end="");
barkingn = input();

for i in range(0, int(barkingn)):
	print("BARK!")
	echo -en "\007"
