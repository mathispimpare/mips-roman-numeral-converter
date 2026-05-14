# Le but de ce programme est de convertir un nombre entre 1 et 3999 entré par l'utilisateur
# en texte correspondant à la notation romaine de ce nombre.
# Il prend donc en entré un entier (integer) comprit entre 1 et 3999 et print la valeur de ce nombre
# encodé en numérotation romaine sous forme de texte.

# Ce programme utilise les registres du processeur et la mémoire
# pour stocker les information nécessaires à la conversion du nombre.

# Vous remarquerez que la fonction repeter est utilisé pour tout les chiffres
# (même si il n'y a pas de répétition d'un chiffre romain) pour ne pas avoir un surplus
# de code dû au copié collé d'instruction pour imprimer un seul chiffre.


# Segment de la mémoire contenant les données globales
.data
# Tampon résérvé pour une chaîne encodée
buffer:	         .space	30
msgInput:	.asciiz "Entrer un nombre de 1 à 3999 : "
msgError:	.asciiz "Le nombre entré est invalide"

unites:    	.asciiz "IVX"
dizaines:  	.asciiz "XLC"
centaines: 	.asciiz "CDM"
milliers:  	.asciiz "M"


#segment de la mémoire contenant le code
.text
main:
	la 	$a0, msgInput
	li 	$v0, 4
	syscall

	# Récupérer l'entrée utilisateur
	li 	$v0, 5
	syscall
	add 	$s0, $v0, $0

	# Vérification que le nombre soit entre 1 et 3999 inclus.
	li 	$t0, 1
	li	$t1, 4000

	slt 	$t3, $s0, $t0
	slt 	$t4, $s0, $t1

	beq 	$t3, $t0, error
	beq	$t4, $0, error
	
	jal 	romain
	
	# Afficher le nombre romain
	la 	$a0, buffer
	li 	$v0, 4
	syscall
	
	# Terminer le programme
	li	$v0, 10
	syscall

romain:
	# Sauvegarder l'adresse de retour à main
	subi 	$sp, $sp, 4
	sw 	$ra, 0($sp)
	
	# Initialiser les arguments pour la fonction chiffre
	move	$a0, $s0
	la 	$a3, buffer
	
	
	li 	$a1, 1000	# $a1 est le rang du digit a traiter (on commence par le digit des milliemes)
	
	# Enregistrer l'adresse de la sous string milliers comme point de départ
	la	$a2, milliers
	
	# Decrementer l'adresse de la sous chaine pour les obtenir la sous chaine centaines, dizaines et unités
	decrement:

	beqz	$a1, end	# On arrête quand on sera au rang 1 (digit unité) cad lorsqu'on decrementera, 1//10 = 0, donc $a2 = 0
	
	# Sauvegarder les arguments avant l'appel de chiffre
	subi	$sp, $sp, 12
	sw 	$a0, 8($sp)
	sw 	$a1, 4($sp)
	sw 	$a2, 0($sp)
	
	jal 	chiffre
	
	# Restaurer les arguments et l'allocation de la mémoire
	lw 	$a0, 8($sp)
	lw 	$a1, 4($sp)
	lw 	$a2, 0($sp)
	addi 	$sp, $sp, 12
	# Actualiser l'adresse du à partir de laquelle il faut placer les caractères
	move 	$a3, $v0
	
	# Decrementer le rang
	li 	$t0, 10
	div 	$a1, $t0
	mflo	$a1
	
	# Decrementer l'adresse de la sous chaine
	subi 	$a2, $a2, 4
	
	j decrement
	
	end:
	sb $zero, 0($a3)
	#Restaurer l'adresse de retour à main
	lw 	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	jr 	$ra

chiffre:
	subi	$sp, $sp, 4
	sw 	$ra, 0($sp)
	
	# Récupérer le digit au rang spécifié et le stocker dans $t1
	li 	$t0, 10
	div 	$a0, $a1
	mflo 	$t1
	div 	$t1, $t0
	mfhi 	$t1
	
	# Sauvegarder l'argument $a1
	move 	$t2, $a1
	
	# Initialiser les arguments de la fonction répéter (on modifiera seulement ce qui aura besoin d'être modifié par la suite)
	move	$a0, $t1
	la 	$a1, ($a2)
	move 	$a2, $a3
	
	# Traiter le digit par cas :
	subi 	$t3, $t2, 1000
	beqz	$t3, milles	# if (rang = 1000); then { j milles }
	
	# Else : on traite par rapport à la valeur du digit
	subi	$t3, $t1, 4
	beqz 	$t3, eqFour	# if (digit == 4); then { j eqFour }
	
	# Else :
	slti	$t4, $t3, 0
	bne	$t4, $0, zeroThree	# if (0 <= digit <= 3);then { j zeroThree }
	
	# Else ( digit >= 5) :
	subi 	$t5, $t1, 9
	beqz	$t5, eqNine	# if (digit == 9); then { j eqNine }
	
	# Else ( 5 <= digit <= 8 ) :
	j fiveEight
	
	zeroThree:	# Répétition du premier caractère de la sous chaine ("I", "X" ou "C")
	jal	repeter
	j	endChiffre
	
	eqFour:		# Possibilités : "IV", "XL" ou "CD". Donc premier caractère collé au deuxième de la sous chaine.
	li 	$a0, 1		# Une répétitions du premier caractère
	jal 	repeter
	
	addi 	$a1, $a1, 1	# Adresse du deuxième caractère
	move 	$a2, $v0	# Actualiser l'adresse où écrire le prochain caractère
	jal 	repeter
	
	j	endChiffre
	
	fiveEight:	# Répétition du premier caractère de la sous chaine ("I", "X" ou "C") après "V", "L" ou "D" (deuxième caractère de la sous chaine).
	li 	$a0, 1		# Une répétition du deuxième caractère
	addi 	$a1, $a1, 1	# Adresse du deuxième caractère
	
	# Sauvegarde de $t1
	subi	$sp, $sp, 4
	sw	$t1, 0($sp)
	
	jal 	repeter
	
	# Restaurer $t1
	lw 	$t1, 0($sp)
	addi	$sp, $sp, 4
	
	subi	$a0, $t1, 5	# Nombre de répétitions du premier caractère (on a déjà encodé le 5 alors on soustrait pour faire le reste
	subi 	$a1, $a1, 1	# Adresse du premier caractère
	move 	$a2, $v0	# Actualiser l'adresse où écrire le prochain caractère
	jal 	repeter
	
	j	endChiffre
	
	eqNine:		# Possibilité : "IX", "XC" ou "DM". Donc premier caractère collé au troisième de la sous chaine.
	li 	$a0, 1		# Une répétitions du premier caractère
	jal 	repeter
	
	addi 	$a1, $a1, 2	# Adresse du troisième caractère
	move 	$a2, $v0
	jal 	repeter
	
	j	endChiffre
	
	milles: # Cas particulier où il n'y aura que des répétitions de "M"
	jal repeter 	# On utilise les arguments par défauts dédinis plus tôt
	
	endChiffre:	# On a fini d'encoder le chiffre, on restaure l'adresse de retour et on retourne à romain
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr 	$ra

repeter:
	move 	$t0, $0		# Nombre de répétition (compteur)
	lb 	$t1, 0($a1)	# Mettre la valeur du caractère ascii dans $t1
	move 	$t2, $a2	# Adresse du resultat (qu'on incrémentera)
	
	loop:			# Boucle de répétition du caractère
	sub	$t3, $t0, $a0
	beqz 	$t3, endLoop
	
	sb	$t1, 0($t2)	# Ecrire le caractère à la suite dans le buffer
	
	# Incrémenter le compteur et l'adresse où écrire pour le prochain caractère
	addi 	$t2, $t2, 1
	addi 	$t0, $t0, 1
	
	j loop
	
	endLoop:
	move 	$v0, $t2	# Sauvegarde de l'adresse suivante où écrire dans le registre résultat de fonction
	jr 	$ra

error:
	# Afficher le message d'erreur
	la 	$a0, msgError
	li 	$v0, 4
	syscall
	
	# Terminer le programme
	li	$v0, 10
	syscall
