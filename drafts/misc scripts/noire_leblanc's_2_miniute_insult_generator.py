import random

part1 = ["lazy", "stupid", "insecure", "idiotic", "slimy", "slutty", "smelly", "pompous", "communist", "dicknose", "pie-eating", "racist", "elitist", "white trash", "drug-loving", "butterface", "tone deaf", "ugly", "creepy"]
part2 = ["douche", "ass", "turd", "rectum", "butt", "cock", "shit", "crotch", "bitch", "turd", "prick", "slut", "taint", "fuck", "dick", "boner", "shart", "nut", "sphincter"]
part3 = ["pilot", "canoe", "captain", "pirate", "hammer", "knob", "box", "jockey", "nazi", "waffle", "goblin", "blossom", "biscuit", "clown", "socket", "monster", "hound", "dragon", "balloon"]
cont = "y"

while(cont == "y"):
    insult1 = part1[random.randint(0,18)]
    insult2 = part2[random.randint(0,18)]
    insult3 = part3[random.randint(0,18)]
    print insult1, insult2, insult3
##    print "continue y/n: "
    cont = str(raw_input("another?"))
    if cont == "Y":
        cont = "y"
    if cont != "y":
        print "Fuck ye then."
    #endif
#endwhile