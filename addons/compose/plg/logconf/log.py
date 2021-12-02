import sys

result=[]
with open('uatserver','r') as f:
   for line in f:
       result.append(line.strip('\n'))
#print(result)

with open('newserver','r') as oldf:
   for oline in oldf:
       if (oline.strip('\n') not in result):
           print(oline.strip('\n')+"=====不在")