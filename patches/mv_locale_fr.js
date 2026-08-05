// Ce fichier contient la liste des fonctions affichées dans l'éditeur MathView,
// regroupées par catégories. Traduction française (Québec) -- voir
// mv_locale_us.js pour la version originale (anglaise) et sa structure.
//   text: code latex affiché sur le bouton
//   autocomp: si la chaîne doit être incluse dans l'autocomplétion
//   tooltip: l'info-bulle affichée au survol du bouton
//   latex: le code latex correspondant à la fonction
//   PG: le code PGML correspondant à la fonction (syntaxe interne WeBWorK,
//       non modifiée -- ne représente pas la notation visuelle)

var mathView_translator = [
	'Base',
	'Parenthèse',
	'Trigonométrie',
	'Logarithmes',
	'Intervalles',
	'Autres',
	'Version FR ',
	'Éditeur d\'équations',
	'Insérer',
	'Annuler',
	'Trigonométrie inverse',
	'Exposants',
	'Opérations'
];

var mv_categories = [
	{
		text: mathView_translator[0], // 'Base'
		operators: [
			{
				text: '\\(a + b\\)',
				autocomp: false,
				tooltip: 'addition',
				latex: '{}+{}',
				PG: '+'
			},
			{
				text: '\\(a-b\\)',
				autocomp: false,
				tooltip: 'soustraction',
				latex: '{}-{}',
				PG: '-'
			},
			{
				text: '\\(a\\cdot b\\)',
				autocomp: false,
				tooltip: 'multiplication',
				latex: '{}*{}',
				PG: '*'
			},
			{
				text: '\\(a/b\\)',
				autocomp: false,
				tooltip: 'division',
				latex: '{}/{}',
				PG: '/'
			},
			{
				text: '\\(\\frac{a}{b}\\)',
				autocomp: false,
				tooltip: 'fraction',
				latex: '\\frac{}{}',
				PG: '()/()'
			},
			{
				text: '\\(|a|\\)',
				autocomp: true,
				tooltip: 'valeur absolue',
				latex: '|{}|',
				PG: 'abs()'
			}
		]
	},
	{
		text: mathView_translator[11], // 'Exposants'
		operators: [
			{
				text: '\\(a^b\\)',
				autocomp: false,
				tooltip: 'exposant',
				latex: '{}^{}',
				PG: '^'
			},
			{
				text: '\\(\\sqrt{a}\\)',
				autocomp: true,
				tooltip: 'racine carrée',
				latex: '\\sqrt{}',
				PG: 'sqrt()'
			},
			{
				text: '\\(\\sqrt[b]{a}\\)',
				autocomp: false,
				tooltip: 'racine b-ième',
				latex: '\\sqrt[]{}',
				PG: '^(1/b)'
			},
			{
				text: '\\(e^{a}\\)',
				autocomp: false,
				tooltip: 'exponentielle',
				latex: 'e^{}',
				PG: 'e^()'
			}
		]
	},
	{
		text: mathView_translator[2], // 'Trigonométrie'
		operators: [
			{
				text: '\\(\\sin(a)\\)',
				autocomp: true,
				tooltip: 'sinus',
				latex: '\\sin{}',
				PG: 'sin()'
			},
			{
				text: '\\(\\cos(a)\\)',
				autocomp: true,
				tooltip: 'cosinus',
				latex: '\\cos{}',
				PG: 'cos()'
			},
			{
				text: '\\(\\tan(a)\\)',
				autocomp: true,
				tooltip: 'tangente',
				latex: '\\tan{}',
				PG: 'tan()'
			},
			{
				text: '\\(\\csc(a)\\)',
				autocomp: true,
				tooltip: 'cosécante',
				latex: '\\csc{}',
				PG: 'csc()'
			},
			{
				text: '\\(\\sec(a)\\)',
				autocomp: true,
				tooltip: 'sécante',
				latex: '\\sec{}',
				PG: 'sec()'
			},
			{
				text: '\\(\\cot(a)\\)',
				autocomp: true,
				tooltip: 'cotangente',
				latex: '\\cot{}',
				PG: 'cot()'
			}
		]
	},
	{
		text: mathView_translator[10], // 'Trigonométrie inverse'
		operators: [
			{
				text: '\\(\\sin^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc sinus',
				latex: '\\sin^{-1}{}',
				PG: 'sin^(-1)()'
			},
			{
				text: '\\(\\cos^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc cosinus',
				latex: '\\cos^{-1}{}',
				PG: 'cos^(-1)()'
			},
			{
				text: '\\(\\tan^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc tangente',
				latex: '\\tan^{-1}{}',
				PG: 'tan^(-1)()'
			},
			{
				text: '\\(\\cot^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc cotangente',
				latex: '\\cot^{-1}{}',
				PG: 'cot^{-1}()'
			},
			{
				text: '\\(\\sec^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc sécante',
				latex: '\\sec^{-1}{}',
				PG: 'sec^(-1)()'
			},
			{
				text: '\\(\\csc^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'arc cosécante',
				latex: '\\csc^{-1}{}',
				PG: 'csc^(-1)()'
			}
		]
	},
	{
		text: mathView_translator[3], // 'Logarithmes'
		operators: [
			{
				text: '\\(\\log(a)\\)',
				tooltip: 'logarithme base 10',
				autocomp: true,
				latex: '\\log{}',
				PG: 'log()'
			},
			{
				text: '\\(\\log_b(a)\\)',
				tooltip: 'logarithme base b',
				latex: '\\log_{}{}',
				PG: 'log()/log()'
			},
			{
				text: '\\(\\ln(a)\\)',
				autocomp: true,
				tooltip: 'logarithme naturel',
				latex: '\\ln{}',
				PG: 'ln()'
			},
			{
				text: '\\(\\exp(a)\\)',
				autocomp: true,
				tooltip: 'exponentielle',
				latex: '\\exp{}',
				PG: 'exp()'
			}
		]
	},
	{
		text: mathView_translator[4], // 'Intervalles'
		// Notation québécoise : les crochets pointent vers l'extérieur pour
		// une extrémité ouverte (ex. ]a,b[ plutôt que (a,b)), au lieu des
		// parenthèses. Seuls "text" (étiquette visuelle) et "latex" (modèle
		// inséré) sont ajustés ; "PG" reste la syntaxe interne de WeBWorK,
		// indépendante de la convention de notation visuelle.
		operators: [
			{
				text: '\\([a,b]\\)',
				tooltip: 'intervalle fermé',
				latex: '\\left[{},{} \\right]',
				PG: '[,]'
			},
			{
				text: '\\(]a,b]\\)',
				tooltip: 'intervalle semi-ouvert',
				latex: '\\left]{},{} \\right]',
				PG: '(,]'
			},
			{
				text: '\\([a,b[\\)',
				tooltip: 'intervalle semi-ouvert',
				latex: '\\left[{},{} \\right[',
				PG: '[,)'
			},
			{
				text: '\\(]a,b[\\)',
				tooltip: 'intervalle ouvert',
				latex: '\\left]{},{} \\right[',
				PG: '(,)'
			},
			{
				text: '\\(A\\cup B\\)',
				tooltip: 'union',
				latex: '\\cup',
				PG: 'U'
			}
		]
	},
	{
		text: mathView_translator[5], // 'Autres'
		operators: [
			{
				text: '\\(\\infty\\)',
				autocomp: true,
				tooltip: 'infini',
				latex: '\\infty',
				PG: 'Inf'
			},

			{
				text: '\\(\\pi\\)',
				tooltip: 'Pi',
				latex: '\\pi',
				PG: 'pi'
			},
			{
				text: '\\(e\\)',
				tooltip: 'nombre e (constante d\'Euler)',
				latex: 'e',
				PG: 'e'
			},
			{
				text: '\\((a)\\)',
				tooltip: 'parenthèses',
				latex: '()',
				PG: '()'
			},
			{
				text: '\\([a]\\)',
				tooltip: 'crochets',
				latex: '[]',
				PG: '[]'
			},
			{
				text: '\\(\\{a\\}\\)',
				tooltip: 'accolades',
				latex: '\\left \\{  \\right \\}',
				PG: '{}'
			}
		]
	}
];
