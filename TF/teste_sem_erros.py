import math
import sys

base = 10 + 2 * 5
fator = (10 + 2) * 5.5
media = fator / 2 - 1

def processar_dados(a, b, limite):
	total = a + b
	if total >= limite:
		while total > 0:
			total = total - 1
		return total
	else:
		for item in base:
			if item != 0:
				total = total + item
		return 0

def funcao_sem_parametros():
	x = 100
	if x <= 50:
		return x
	if x == 100:
		return x + 1

return media
