import pandas as pd
import random

data = []

for _ in range(100):
    iq = random.randint(80,120)
    cgpa = round(random.uniform(6.0,10.0),2)
    placed = 1 if iq * 0.5 + cgpa * 10 > 130 else 0
    data.append([iq,cgpa,placed])

df = pd.DataFrame(data, columns=['IQ', 'CGPA', 'Placed'])

df.to_csv("Placement_data.csv", index=False)

print("Done")