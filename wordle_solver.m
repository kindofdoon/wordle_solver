% function wordle_solver

    % A computer program to solve the word-guessing game "Wordle",
    % located at https://www.powerlanguage.co.uk/wordle/
    
    % Uses statistically-informed guesses, game heuristics, and process of
    % elimination to determine the solution in as few moves as possible.
    
    % Case-sensitive. Must use lowercase only.
    
    % Usermodes:
        % 'manual'
            % The program suggests optimal next guesses. The player
            % manually informs the program of their guesses and the
            % responses.
        % 'auto'
            % The program plays against itself. The user can specify a set
            % of solutions to solve, or the number of randomized games to
            % play.
        % 'debug'
            % The program plays against itself as in 'auto' mode, but
            % pauses after each move to show some diagnostic data
    
    % Responses use the following syntax:
        % 'k': gray, not in word
        % 'y': yellow, in word, but not in that spot
        % 'g': green, in word, in that spot
    
    % Daniel W. Dichter
    % daniel.w.dichter@gmail.com
    
    % Changelog:
        % 2022-01-11:
            % First version
        % 2022-01-16:
            % Revised to support words with multi-instance letters, e.g. WADED, DOORS, etc.
            % Swapped in a better dictionary with 4k 5-letter words (previously, 16k)
        % 2022-01-19:
            % Added suggestions of good guesses based on letter distribution
        % 2022-01-23:
            % Now makes optimized guesses against the dictionary (rather than
            % the set of possible words) for faster convergence. For 25 trials,
            % produced MEAN of 3.88 with STDEV of 0.88
        % 2022-01-24:
            % Added actual Wordle guess and solution dictionaries
            % Now can automatically play against itself
            % 100 trials, 3.69 mean, 0.61 stdev, worst score of 5
        % 2022-01-25:
            % Minor cleanup, documentation improvements
        % 2022-01-28:
            % Improved guess selection by seeing if any top-value guesses
            % are also possible solutions. Fixed a bug that was penalizing
            % words with repeated letters. Improved elimination with gray
            % tiles and matching letters.
    
    %%
    
    clear
    clc
    
    %% Inputs
    
    usermode      = 'auto'; % 'auto', 'manual', or 'debug'
    auto_game_qty = 100; % 'auto'   usermode - number of iterations to perform
    qty_suggest   = 5;   % 'manual' usermode - number of words to show after every guess
    auto_list     = {    % 'auto'   usermode - specific solutions to solve
                    'aback' 'abase' 'abate' 'abbey' 'abbot' 'abhor' 'abide' 'abled' 'abode' 'abort' 'about' 'above' 'abuse' 'abyss' 'acorn' 'acrid' 'actor' 'acute' 'adage' 'adapt' 'adept' 'admin' 'admit' 'adobe' 'adopt' 'adore' 'adorn' 'adult' 'affix' 'afire' 'afoot' 'afoul' 'after' 'again' 'agape' 'agate' 'agent' 'agile' 'aging' 'aglow' 'agony' 'agora' 'agree' 'ahead' 'aider' 'aisle' 'alarm' 'album' 'alert' 'algae' 'alibi' 'alien' 'align' 'alike' 'alive' 'allay' 'alley' 'allot' 'allow' 'alloy' 'aloft' 'alone' 'along' 'aloof' 'aloud' 'alpha' 'altar' 'alter' 'amass' 'amaze' 'amber' 'amble' 'amend' 'amiss' 'amity' 'among' 'ample' 'amply' 'amuse' 'angel' 'anger' 'angle' 'angry' 'angst' 'anime' 'ankle' 'annex' 'annoy' 'annul' 'anode' 'antic' 'anvil' 'aorta' 'apart' 'aphid' 'aping' 'apnea' 'apple' 'apply' 'apron' 'aptly' 'arbor' 'ardor' 'arena' 'argue' 'arise' 'armor' 'aroma' 'arose' 'array' 'arrow' 'arson' 'artsy' 'ascot' 'ashen' 'aside' 'askew' 'assay' 'asset' 'atoll' 'atone' 'attic' 'audio' 'audit' 'augur' 'aunty' 'avail' 'avert' 'avian' 'avoid' 'await' 'awake' 'award' 'aware' 'awash' 'awful' 'awoke' 'axial' 'axiom' 'axion' 'azure' 'bacon' 'badge' 'badly' 'bagel' 'baggy' 'baker' 'baler' 'balmy' 'banal' 'banjo' 'barge' 'baron' 'basal' 'basic' 'basil' 'basin' 'basis' 'baste' 'batch' 'bathe' 'baton' 'batty' 'bawdy' 'bayou' 'beach' 'beady' 'beard' 'beast' 'beech' 'beefy' 'befit' 'began' 'begat' 'beget' 'begin' 'begun' 'being' 'belch' 'belie' 'belle' 'belly' 'below' 'bench' 'beret' 'berry' 'berth' 'beset' 'betel' 'bevel' 'bezel' 'bible' 'bicep' 'biddy' 'bigot' 'bilge' 'billy' 'binge' 'bingo' 'biome' 'birch' 'birth' 'bison' 'bitty' 'black' 'blade' 'blame' 'bland' 'blank' 'blare' 'blast' 'blaze' 'bleak' 'bleat' 'bleed' 'bleep' 'blend' 'bless' 'blimp' 'blind' 'blink' 'bliss' 'blitz' 'bloat' 'block' 'bloke' 'blond' 'blood' 'bloom' 'blown' 'bluer' 'bluff' 'blunt' 'blurb' 'blurt' 'blush' 'board' 'boast' 'bobby' 'boney' 'bongo' 'bonus' 'booby' 'boost' 'booth' 'booty' 'booze' 'boozy' 'borax' 'borne' 'bosom' 'bossy' 'botch' 'bough' 'boule' 'bound' 'bowel' 'boxer' 'brace' 'braid' 'brain' 'brake' 'brand' 'brash' 'brass' 'brave' 'bravo' 'brawl' 'brawn' 'bread' 'break' 'breed' 'briar' 'bribe' 'brick' 'bride' 'brief' 'brine' 'bring' 'brink' 'briny' 'brisk' 'broad' 'broil' 'broke' 'brood' 'brook' 'broom' 'broth' 'brown' 'brunt' 'brush' 'brute' 'buddy' 'budge' 'buggy' 'bugle' 'build' 'built' 'bulge' 'bulky' 'bully' 'bunch' 'bunny' 'burly' 'burnt' 'burst' 'bused' 'bushy' 'butch' 'butte' 'buxom' 'buyer' 'bylaw' 'cabal' 'cabby' 'cabin' 'cable' 'cacao' 'cache' 'cacti' 'caddy' 'cadet' 'cagey' 'cairn' 'camel' 'cameo' 'canal' 'candy' 'canny' 'canoe' 'canon' 'caper' 'caput' 'carat' 'cargo' 'carol' 'carry' 'carve' 'caste' 'catch' 'cater' 'catty' 'caulk' 'cause' 'cavil' 'cease' 'cedar' 'cello' 'chafe' 'chaff' 'chain' 'chair' 'chalk' 'champ' 'chant' 'chaos' 'chard' 'charm' 'chart' 'chase' 'chasm' 'cheap' 'cheat' 'check' 'cheek' 'cheer' 'chess' 'chest' 'chick' 'chide' 'chief' 'child' 'chili' 'chill' 'chime' 'china' 'chirp' 'chock' 'choir' 'choke' 'chord' 'chore' 'chose' 'chuck' 'chump' 'chunk' 'churn' 'chute' 'cider' 'cigar' 'cinch' 'circa' 'civic' 'civil' 'clack' 'claim' 'clamp' 'clang' 'clank' 'clash' 'clasp' 'class' 'clean' 'clear' 'cleat' 'cleft' 'clerk' 'click' 'cliff' 'climb' 'cling' 'clink' 'cloak' 'clock' 'clone' 'close' 'cloth' 'cloud' 'clout' 'clove' 'clown' 'cluck' 'clued' 'clump' 'clung' 'coach' 'coast' 'cobra' 'cocoa' 'colon' 'color' 'comet' 'comfy' 'comic' 'comma' 'conch' 'condo' 'conic' 'copse' 'coral' 'corer' 'corny' 'couch' 'cough' 'could' 'count' 'coupe' 'court' 'coven' 'cover' 'covet' 'covey' 'cower' 'coyly' 'crack' 'craft' 'cramp' 'crane' 'crank' 'crash' 'crass' 'crate' 'crave' 'crawl' 'craze' 'crazy' 'creak' 'cream' 'credo' 'creed' 'creek' 'creep' 'creme' 'crepe' 'crept' 'cress' 'crest' 'crick' 'cried' 'crier' 'crime' 'crimp' 'crisp' 'croak' 'crock' 'crone' 'crony' 'crook' 'cross' 'croup' 'crowd' 'crown' 'crude' 'cruel' 'crumb' 'crump' 'crush' 'crust' 'crypt' 'cubic' 'cumin' 'curio' 'curly' 'curry' 'curse' 'curve' 'curvy' 'cutie' 'cyber' 'cycle' 'cynic' 'daddy' 'daily' 'dairy' 'daisy' 'dally' 'dance' 'dandy' 'datum' 'daunt' 'dealt' 'death' 'debar' 'debit' 'debug' 'debut' 'decal' 'decay' 'decor' 'decoy' 'decry' 'defer' 'deign' 'deity' 'delay' 'delta' 'delve' 'demon' 'demur' 'denim' 'dense' 'depot' 'depth' 'derby' 'deter' 'detox' 'deuce' 'devil' 'diary' 'dicey' 'digit' 'dilly' 'dimly' 'diner' 'dingo' 'dingy' 'diode' 'dirge' 'dirty' 'disco' 'ditch' 'ditto' 'ditty' 'diver' 'dizzy' 'dodge' 'dodgy' 'dogma' 'doing' 'dolly' 'donor' 'donut' 'dopey' 'doubt' 'dough' 'dowdy' 'dowel' 'downy' 'dowry' 'dozen' 'draft' 'drain' 'drake' 'drama' 'drank' 'drape' 'drawl' 'drawn' 'dread' 'dream' 'dress' 'dried' 'drier' 'drift' 'drill' 'drink' 'drive' 'droit' 'droll' 'drone' 'drool' 'droop' 'dross' 'drove' 'drown' 'druid' 'drunk' 'dryer' 'dryly' 'duchy' 'dully' 'dummy' 'dumpy' 'dunce' 'dusky' 'dusty' 'dutch' 'duvet' 'dwarf' 'dwell' 'dwelt' 'dying' 'eager' 'eagle' 'early' 'earth' 'easel' 'eaten' 'eater' 'ebony' 'eclat' 'edict' 'edify' 'eerie' 'egret' 'eight' 'eject' 'eking' 'elate' 'elbow' 'elder' 'elect' 'elegy' 'elfin' 'elide' 'elite' 'elope' 'elude' 'email' 'embed' 'ember' 'emcee' 'empty' 'enact' 'endow' 'enema' 'enemy' 'enjoy' 'ennui' 'ensue' 'enter' 'entry' 'envoy' 'epoch' 'epoxy' 'equal' 'equip' 'erase' 'erect' 'erode' 'error' 'erupt' 'essay' 'ester' 'ether' 'ethic' 'ethos' 'etude' 'evade' 'event' 'every' 'evict' 'evoke' 'exact' 'exalt' 'excel' 'exert' 'exile' 'exist' 'expel' 'extol' 'extra' 'exult' 'eying' 'fable' 'facet' 'faint' 'fairy' 'faith' 'false' 'fancy' 'fanny' 'farce' 'fatal' 'fatty' 'fault' 'fauna' 'favor' 'feast' 'fecal' 'feign' 'fella' 'felon' 'femme' 'femur' 'fence' 'feral' 'ferry' 'fetal' 'fetch' 'fetid' 'fetus' 'fever' 'fewer' 'fiber' 'fibre' 'ficus' 'field' 'fiend' 'fiery' 'fifth' 'fifty' 'fight' 'filer' 'filet' 'filly' 'filmy' 'filth' 'final' 'finch' 'finer' 'first' 'fishy' 'fixer' 'fizzy' 'fjord' 'flack' 'flail' 'flair' 'flake' 'flaky' 'flame' 'flank' 'flare' 'flash' 'flask' 'fleck' 'fleet' 'flesh' 'flick' 'flier' 'fling' 'flint' 'flirt' 'float' 'flock' 'flood' 'floor' 'flora' 'floss' 'flour' 'flout' 'flown' 'fluff' 'fluid' 'fluke' 'flume' 'flung' 'flunk' 'flush' 'flute' 'flyer' 'foamy' 'focal' 'focus' 'foggy' 'foist' 'folio' 'folly' 'foray' 'force' 'forge' 'forgo' 'forte' 'forth' 'forty' 'forum' 'found' 'foyer' 'frail' 'frame' 'frank' 'fraud' 'freak' 'freed' 'freer' 'fresh' 'friar' 'fried' 'frill' 'frisk' 'fritz' 'frock' 'frond' 'front' 'frost' 'froth' 'frown' 'froze' 'fruit' 'fudge' 'fugue' 'fully' 'fungi' 'funky' 'funny' 'furor' 'furry' 'fussy' 'fuzzy' 'gaffe' 'gaily' 'gamer' 'gamma' 'gamut' 'gassy' 'gaudy' 'gauge' 'gaunt' 'gauze' 'gavel' 'gawky' 'gayer' 'gayly' 'gazer' 'gecko' 'geeky' 'geese' 'genie' 'genre' 'ghost' 'ghoul' 'giant' 'giddy' 'gipsy' 'girly' 'girth' 'given' 'giver' 'glade' 'gland' 'glare' 'glass' 'glaze' 'gleam' 'glean' 'glide' 'glint' 'gloat' 'globe' 'gloom' 'glory' 'gloss' 'glove' 'glyph' 'gnash' 'gnome' 'godly' 'going' 'golem' 'golly' 'gonad' 'goner' 'goody' 'gooey' 'goofy' 'goose' 'gorge' 'gouge' 'gourd' 'grace' 'grade' 'graft' 'grail' 'grain' 'grand' 'grant' 'grape' 'graph' 'grasp' 'grass' 'grate' 'grave' 'gravy' 'graze' 'great' 'greed' 'green' 'greet' 'grief' 'grill' 'grime' 'grimy' 'grind' 'gripe' 'groan' 'groin' 'groom' 'grope' 'gross' 'group' 'grout' 'grove' 'growl' 'grown' 'gruel' 'gruff' 'grunt' 'guard' 'guava' 'guess' 'guest' 'guide' 'guild' 'guile' 'guilt' 'guise' 'gulch' 'gully' 'gumbo' 'gummy' 'guppy' 'gusto' 'gusty' 'gypsy' 'habit' 'hairy' 'halve' 'handy' 'happy' 'hardy' 'harem' 'harpy' 'harry' 'harsh' 'haste' 'hasty' 'hatch' 'hater' 'haunt' 'haute' 'haven' 'havoc' 'hazel' 'heady' 'heard' 'heart' 'heath' 'heave' 'heavy' 'hedge' 'hefty' 'heist' 'helix' 'hello' 'hence' 'heron' 'hilly' 'hinge' 'hippo' 'hippy' 'hitch' 'hoard' 'hobby' 'hoist' 'holly' 'homer' 'honey' 'honor' 'horde' 'horny' 'horse' 'hotel' 'hotly' 'hound' 'house' 'hovel' 'hover' 'howdy' 'human' 'humid' 'humor' 'humph' 'humus' 'hunch' 'hunky' 'hurry' 'husky' 'hussy' 'hutch' 'hydro' 'hyena' 'hymen' 'hyper' 'icily' 'icing' 'ideal' 'idiom' 'idiot' 'idler' 'idyll' 'igloo' 'iliac' 'image' 'imbue' 'impel' 'imply' 'inane' 'inbox' 'incur' 'index' 'inept' 'inert' 'infer' 'ingot' 'inlay' 'inlet' 'inner' 'input' 'inter' 'intro' 'ionic' 'irate' 'irony' 'islet' 'issue' 'itchy' 'ivory' 'jaunt' 'jazzy' 'jelly' 'jerky' 'jetty' 'jewel' 'jiffy' 'joint' 'joist' 'joker' 'jolly' 'joust' 'judge' 'juice' 'juicy' 'jumbo' 'jumpy' 'junta' 'junto' 'juror' 'kappa' 'karma' 'kayak' 'kebab' 'khaki' 'kinky' 'kiosk' 'kitty' 'knack' 'knave' 'knead' 'kneed' 'kneel' 'knelt' 'knife' 'knock' 'knoll' 'known' 'koala' 'krill' 'label' 'labor' 'laden' 'ladle' 'lager' 'lance' 'lanky' 'lapel' 'lapse' 'large' 'larva' 'lasso' 'latch' 'later' 'lathe' 'latte' 'laugh' 'layer' 'leach' 'leafy' 'leaky' 'leant' 'leapt' 'learn' 'lease' 'leash' 'least' 'leave' 'ledge' 'leech' 'leery' 'lefty' 'legal' 'leggy' 'lemon' 'lemur' 'leper' 'level' 'lever' 'libel' 'liege' 'light' 'liken' 'lilac' 'limbo' 'limit' 'linen' 'liner' 'lingo' 'lipid' 'lithe' 'liver' 'livid' 'llama' 'loamy' 'loath' 'lobby' 'local' 'locus' 'lodge' 'lofty' 'logic' 'login' 'loopy' 'loose' 'lorry' 'loser' 'louse' 'lousy' 'lover' 'lower' 'lowly' 'loyal' 'lucid' 'lucky' 'lumen' 'lumpy' 'lunar' 'lunch' 'lunge' 'lupus' 'lurch' 'lurid' 'lusty' 'lying' 'lymph' 'lynch' 'lyric' 'macaw' 'macho' 'macro' 'madam' 'madly' 'mafia' 'magic' 'magma' 'maize' 'major' 'maker' 'mambo' 'mamma' 'mammy' 'manga' 'mange' 'mango' 'mangy' 'mania' 'manic' 'manly' 'manor' 'maple' 'march' 'marry' 'marsh' 'mason' 'masse' 'match' 'matey' 'mauve' 'maxim' 'maybe' 'mayor' 'mealy' 'meant' 'meaty' 'mecca' 'medal' 'media' 'medic' 'melee' 'melon' 'mercy' 'merge' 'merit' 'merry' 'metal' 'meter' 'metro' 'micro' 'midge' 'midst' 'might' 'milky' 'mimic' 'mince' 'miner' 'minim' 'minor' 'minty' 'minus' 'mirth' 'miser' 'missy' 'mocha' 'modal' 'model' 'modem' 'mogul' 'moist' 'molar' 'moldy' 'money' 'month' 'moody' 'moose' 'moral' 'moron' 'morph' 'mossy' 'motel' 'motif' 'motor' 'motto' 'moult' 'mound' 'mount' 'mourn' 'mouse' 'mouth' 'mover' 'movie' 'mower' 'mucky' 'mucus' 'muddy' 'mulch' 'mummy' 'munch' 'mural' 'murky' 'mushy' 'music' 'musky' 'musty' 'myrrh' 'nadir' 'naive' 'nanny' 'nasal' 'nasty' 'natal' 'naval' 'navel' 'needy' 'neigh' 'nerdy' 'nerve' 'never' 'newer' 'newly' 'nicer' 'niche' 'niece' 'night' 'ninja' 'ninny' 'ninth' 'noble' 'nobly' 'noise' 'noisy' 'nomad' 'noose' 'north' 'nosey' 'notch' 'novel' 'nudge' 'nurse' 'nutty' 'nylon' 'nymph' 'oaken' 'obese' 'occur' 'ocean' 'octal' 'octet' 'odder' 'oddly' 'offal' 'offer' 'often' 'olden' 'older' 'olive' 'ombre' 'omega' 'onion' 'onset' 'opera' 'opine' 'opium' 'optic' 'orbit' 'order' 'organ' 'other' 'otter' 'ought' 'ounce' 'outdo' 'outer' 'outgo' 'ovary' 'ovate' 'overt' 'ovine' 'ovoid' 'owing' 'owner' 'oxide' 'ozone' 'paddy' 'pagan' 'paint' 'paler' 'palsy' 'panel' 'panic' 'pansy' 'papal' 'paper' 'parer' 'parka' 'parry' 'parse' 'party' 'pasta' 'paste' 'pasty' 'patch' 'patio' 'patsy' 'patty' 'pause' 'payee' 'payer' 'peace' 'peach' 'pearl' 'pecan' 'pedal' 'penal' 'pence' 'penne' 'penny' 'perch' 'peril' 'perky' 'pesky' 'pesto' 'petal' 'petty' 'phase' 'phone' 'phony' 'photo' 'piano' 'picky' 'piece' 'piety' 'piggy' 'pilot' 'pinch' 'piney' 'pinky' 'pinto' 'piper' 'pique' 'pitch' 'pithy' 'pivot' 'pixel' 'pixie' 'pizza' 'place' 'plaid' 'plain' 'plait' 'plane' 'plank' 'plant' 'plate' 'plaza' 'plead' 'pleat' 'plied' 'plier' 'pluck' 'plumb' 'plume' 'plump' 'plunk' 'plush' 'poesy' 'point' 'poise' 'poker' 'polar' 'polka' 'polyp' 'pooch' 'poppy' 'porch' 'poser' 'posit' 'posse' 'pouch' 'pound' 'pouty' 'power' 'prank' 'prawn' 'preen' 'press' 'price' 'prick' 'pride' 'pried' 'prime' 'primo' 'print' 'prior' 'prism' 'privy' 'prize' 'probe' 'prone' 'prong' 'proof' 'prose' 'proud' 'prove' 'prowl' 'proxy' 'prude' 'prune' 'psalm' 'pubic' 'pudgy' 'puffy' 'pulpy' 'pulse' 'punch' 'pupal' 'pupil' 'puppy' 'puree' 'purer' 'purge' 'purse' 'pushy' 'putty' 'pygmy' 'quack' 'quail' 'quake' 'qualm' 'quark' 'quart' 'quash' 'quasi' 'queen' 'queer' 'quell' 'query' 'quest' 'queue' 'quick' 'quiet' 'quill' 'quilt' 'quirk' 'quite' 'quota' 'quote' 'quoth' 'rabbi' 'rabid' 'racer' 'radar' 'radii' 'radio' 'rainy' 'raise' 'rajah' 'rally' 'ralph' 'ramen' 'ranch' 'randy' 'range' 'rapid' 'rarer' 'raspy' 'ratio' 'ratty' 'raven' 'rayon' 'razor' 'reach' 'react' 'ready' 'realm' 'rearm' 'rebar' 'rebel' 'rebus' 'rebut' 'recap' 'recur' 'recut' 'reedy' 'refer' 'refit' 'regal' 'rehab' 'reign' 'relax' 'relay' 'relic' 'remit' 'renal' 'renew' 'repay' 'repel' 'reply' 'rerun' 'reset' 'resin' 'retch' 'retro' 'retry' 'reuse' 'revel' 'revue' 'rhino' 'rhyme' 'rider' 'ridge' 'rifle' 'right' 'rigid' 'rigor' 'rinse' 'ripen' 'riper' 'risen' 'riser' 'risky' 'rival' 'river' 'rivet' 'roach' 'roast' 'robin' 'robot' 'rocky' 'rodeo' 'roger' 'rogue' 'roomy' 'roost' 'rotor' 'rouge' 'rough' 'round' 'rouse' 'route' 'rover' 'rowdy' 'rower' 'royal' 'ruddy' 'ruder' 'rugby' 'ruler' 'rumba' 'rumor' 'rupee' 'rural' 'rusty' 'sadly' 'safer' 'saint' 'salad' 'sally' 'salon' 'salsa' 'salty' 'salve' 'salvo' 'sandy' 'saner' 'sappy' 'sassy' 'satin' 'satyr' 'sauce' 'saucy' 'sauna' 'saute' 'savor' 'savoy' 'savvy' 'scald' 'scale' 'scalp' 'scaly' 'scamp' 'scant' 'scare' 'scarf' 'scary' 'scene' 'scent' 'scion' 'scoff' 'scold' 'scone' 'scoop' 'scope' 'score' 'scorn' 'scour' 'scout' 'scowl' 'scram' 'scrap' 'scree' 'screw' 'scrub' 'scrum' 'scuba' 'sedan' 'seedy' 'segue' 'seize' 'semen' 'sense' 'sepia' 'serif' 'serum' 'serve' 'setup' 'seven' 'sever' 'sewer' 'shack' 'shade' 'shady' 'shaft' 'shake' 'shaky' 'shale' 'shall' 'shalt' 'shame' 'shank' 'shape' 'shard' 'share' 'shark' 'sharp' 'shave' 'shawl' 'shear' 'sheen' 'sheep' 'sheer' 'sheet' 'sheik' 'shelf' 'shell' 'shied' 'shift' 'shine' 'shiny' 'shire' 'shirk' 'shirt' 'shoal' 'shock' 'shone' 'shook' 'shoot' 'shore' 'shorn' 'short' 'shout' 'shove' 'shown' 'showy' 'shrew' 'shrub' 'shrug' 'shuck' 'shunt' 'shush' 'shyly' 'siege' 'sieve' 'sight' 'sigma' 'silky' 'silly' 'since' 'sinew' 'singe' 'siren' 'sissy' 'sixth' 'sixty' 'skate' 'skier' 'skiff' 'skill' 'skimp' 'skirt' 'skulk' 'skull' 'skunk' 'slack' 'slain' 'slang' 'slant' 'slash' 'slate' 'slave' 'sleek' 'sleep' 'sleet' 'slept' 'slice' 'slick' 'slide' 'slime' 'slimy' 'sling' 'slink' 'sloop' 'slope' 'slosh' 'sloth' 'slump' 'slung' 'slunk' 'slurp' 'slush' 'slyly' 'smack' 'small' 'smart' 'smash' 'smear' 'smell' 'smelt' 'smile' 'smirk' 'smite' 'smith' 'smock' 'smoke' 'smoky' 'smote' 'snack' 'snail' 'snake' 'snaky' 'snare' 'snarl' 'sneak' 'sneer' 'snide' 'sniff' 'snipe' 'snoop' 'snore' 'snort' 'snout' 'snowy' 'snuck' 'snuff' 'soapy' 'sober' 'soggy' 'solar' 'solid' 'solve' 'sonar' 'sonic' 'sooth' 'sooty' 'sorry' 'sound' 'south' 'sower' 'space' 'spade' 'spank' 'spare' 'spark' 'spasm' 'spawn' 'speak' 'spear' 'speck' 'speed' 'spell' 'spelt' 'spend' 'spent' 'sperm' 'spice' 'spicy' 'spied' 'spiel' 'spike' 'spiky' 'spill' 'spilt' 'spine' 'spiny' 'spire' 'spite' 'splat' 'split' 'spoil' 'spoke' 'spoof' 'spook' 'spool' 'spoon' 'spore' 'sport' 'spout' 'spray' 'spree' 'sprig' 'spunk' 'spurn' 'spurt' 'squad' 'squat' 'squib' 'stack' 'staff' 'stage' 'staid' 'stain' 'stair' 'stake' 'stale' 'stalk' 'stall' 'stamp' 'stand' 'stank' 'stare' 'stark' 'start' 'stash' 'state' 'stave' 'stead' 'steak' 'steal' 'steam' 'steed' 'steel' 'steep' 'steer' 'stein' 'stern' 'stick' 'stiff' 'still' 'stilt' 'sting' 'stink' 'stint' 'stock' 'stoic' 'stoke' 'stole' 'stomp' 'stone' 'stony' 'stood' 'stool' 'stoop' 'store' 'stork' 'storm' 'story' 'stout' 'stove' 'strap' 'straw' 'stray' 'strip' 'strut' 'stuck' 'study' 'stuff' 'stump' 'stung' 'stunk' 'stunt' 'style' 'suave' 'sugar' 'suing' 'suite' 'sulky' 'sully' 'sumac' 'sunny' 'super' 'surer' 'surge' 'surly' 'sushi' 'swami' 'swamp' 'swarm' 'swash' 'swath' 'swear' 'sweat' 'sweep' 'sweet' 'swell' 'swept' 'swift' 'swill' 'swine' 'swing' 'swirl' 'swish' 'swoon' 'swoop' 'sword' 'swore' 'sworn' 'swung' 'synod' 'syrup' 'tabby' 'table' 'taboo' 'tacit' 'tacky' 'taffy' 'taint' 'taken' 'taker' 'tally' 'talon' 'tamer' 'tango' 'tangy' 'taper' 'tapir' 'tardy' 'tarot' 'taste' 'tasty' 'tatty' 'taunt' 'tawny' 'teach' 'teary' 'tease' 'teddy' 'teeth' 'tempo' 'tenet' 'tenor' 'tense' 'tenth' 'tepee' 'tepid' 'terra' 'terse' 'testy' 'thank' 'theft' 'their' 'theme' 'there' 'these' 'theta' 'thick' 'thief' 'thigh' 'thing' 'think' 'third' 'thong' 'thorn' 'those' 'three' 'threw' 'throb' 'throw' 'thrum' 'thumb' 'thump' 'thyme' 'tiara' 'tibia' 'tidal' 'tiger' 'tight' 'tilde' 'timer' 'timid' 'tipsy' 'titan' 'tithe' 'title' 'toast' 'today' 'toddy' 'token' 'tonal' 'tonga' 'tonic' 'tooth' 'topaz' 'topic' 'torch' 'torso' 'torus' 'total' 'totem' 'touch' 'tough' 'towel' 'tower' 'toxic' 'toxin' 'trace' 'track' 'tract' 'trade' 'trail' 'train' 'trait' 'tramp' 'trash' 'trawl' 'tread' 'treat' 'trend' 'triad' 'trial' 'tribe' 'trice' 'trick' 'tried' 'tripe' 'trite' 'troll' 'troop' 'trope' 'trout' 'trove' 'truce' 'truck' 'truer' 'truly' 'trump' 'trunk' 'truss' 'trust' 'truth' 'tryst' 'tubal' 'tuber' 'tulip' 'tulle' 'tumor' 'tunic' 'turbo' 'tutor' 'twang' 'tweak' 'tweed' 'tweet' 'twice' 'twine' 'twirl' 'twist' 'twixt' 'tying' 'udder' 'ulcer' 'ultra' 'umbra' 'uncle' 'uncut' 'under' 'undid' 'undue' 'unfed' 'unfit' 'unify' 'union' 'unite' 'unity' 'unlit' 'unmet' 'unset' 'untie' 'until' 'unwed' 'unzip' 'upper' 'upset' 'urban' 'urine' 'usage' 'usher' 'using' 'usual' 'usurp' 'utile' 'utter' 'vague' 'valet' 'valid' 'valor' 'value' 'valve' 'vapid' 'vapor' 'vault' 'vaunt' 'vegan' 'venom' 'venue' 'verge' 'verse' 'verso' 'verve' 'vicar' 'video' 'vigil' 'vigor' 'villa' 'vinyl' 'viola' 'viper' 'viral' 'virus' 'visit' 'visor' 'vista' 'vital' 'vivid' 'vixen' 'vocal' 'vodka' 'vogue' 'voice' 'voila' 'vomit' 'voter' 'vouch' 'vowel' 'vying' 'wacky' 'wafer' 'wager' 'wagon' 'waist' 'waive' 'waltz' 'warty' 'waste' 'watch' 'water' 'waver' 'waxen' 'weary' 'weave' 'wedge' 'weedy' 'weigh' 'weird' 'welch' 'welsh' 'wench' 'whack' 'whale' 'wharf' 'wheat' 'wheel' 'whelp' 'where' 'which' 'whiff' 'while' 'whine' 'whiny' 'whirl' 'whisk' 'white' 'whole' 'whoop' 'whose' 'widen' 'wider' 'widow' 'width' 'wield' 'wight' 'willy' 'wimpy' 'wince' 'winch' 'windy' 'wiser' 'wispy' 'witch' 'witty' 'woken' 'woman' 'women' 'woody' 'wooer' 'wooly' 'woozy' 'wordy' 'world' 'worry' 'worse' 'worst' 'worth' 'would' 'wound' 'woven' 'wrack' 'wrath' 'wreak' 'wreck' 'wrest' 'wring' 'wrist' 'write' 'wrong' 'wrote' 'wrung' 'wryly' 'yacht' 'yearn' 'yeast' 'yield' 'young' 'youth' 'zebra' 'zesty' 'zonal'
%                         'batch' 'catch' 'hatch' 'vaunt'
                  };
    
    fn_dict_solutions = 'wordlist_solutions.txt';
    fn_dict_guesses   = 'wordlist_guesses.txt';
    
    % AI parameters
    green_yellow_ratio = 2; % value_green / value_yellow, relative
    Gauss.mean         = 0.5;
    Gauss.stdev        = 0.15;

    %% Constants
    
    alphabet = 'abcdefghijklmnopqrstuvwxyz';
    
    Gauss.res   = 1000;
    Gauss.prob  = linspace(0,1,Gauss.res);
    Gauss.val   = (1./(Gauss.stdev.*sqrt(2.*pi))) .* exp((-1/2).*((Gauss.prob-Gauss.mean)./Gauss.stdev).^2);
    Gauss.val([1,end]) = 0;
    Gauss.val = Gauss.val ./ max(Gauss.val(:));
    
    alpha_cell_array = cell(length(alphabet),1);
    for ind_letter = 1 : length(alphabet)
        alpha_cell_array{ind_letter} = alphabet(ind_letter);
    end
    
    %% Show probability vs. value curve
    
    switch usermode
        case 'auto'
            % Do nothing
        case {'manual', 'debug'}
            figure(5)
                clf
                set(gcf,'color','white')
                plot(Gauss.prob, Gauss.val, 'k')
                grid on
                grid minor
                xlabel('Probability, ~')
                ylabel('Value, ~')
    end
    
    %% Main body for all game(s)
    
    ind_game = 1;
    
    switch usermode
        case {'auto', 'debug'}
            if length(auto_list) >= 1
                auto_game_qty = length(auto_list);
            end
        case 'manual'
            auto_game_qty = 1;
    end
    
    % Record some information
    SOLS   = {};
    SCORES = [];
    timestamp = datestr(now,'yyyy_mm_dd_HH_MM_SS_AM');
    timestamp = regexprep(timestamp, ' ', ''); % delete spaces
    fn_diary  = [mfilename '_log_' timestamp '.txt'];
    diary(fn_diary)
    diary on
    disp(fn_diary)
    
    tic
    
    while ind_game <= auto_game_qty

        %% Initialize

        DICT_SOL = sort(importdata(fn_dict_solutions));
        DICT_GUE = sort(importdata(fn_dict_guesses));
        
        word_length = length(DICT_SOL{1});
        correct_response = repmat('g',[1,word_length]);
        response         = repmat('k',[1,word_length]); % initialize as all wrong

        % Generate the solution
        switch usermode
            case {'auto', 'debug'}
                if length(auto_list) >= 1
                    SOLUTION = auto_list{ind_game};
                else
                    i_sol = randi(length(DICT_SOL),1);
                    SOLUTION = DICT_SOL{i_sol};
                end
                disp(['Game #' num2str(ind_game) ': ' SOLUTION])
            case 'manual'
                % Do nothing
        end

        ind_round = 0;

        while ~strcmp(response,correct_response) && length(DICT_SOL)>=1 % while you haven't gotten it right, but still have more words to guess

            ind_round = ind_round + 1;
            disp(' ')
            disp(['Words remaining: ' num2str(length(DICT_SOL))])

            %% Probability distributions for possible solutions

            PROB = zeros(length(alphabet), word_length);

            switch usermode
                case {'manual','debug'}
                    figure(1)
                        clf
                        set(gcf,'color','white')
                        pos = get(gcf,'position');
                        set(gcf,'position',[pos(1) 50 560 900])
                otherwise
                    % Do nothing
            end

            for ind_position = 1 : word_length

                letters = repmat(' ',[length(DICT_SOL),1]);
                for w = 1 : length(DICT_SOL)
                    letters(w) = DICT_SOL{w}(ind_position);
                end
                qty_words = zeros(length(alphabet),1);
                for ind_letter = 1 : length(alphabet)
                    qty_words(ind_letter) = length(find(letters == alphabet(ind_letter)));
                end
                PROB(:,ind_position) = qty_words ./ length(DICT_SOL); % normalize from counts to probabilities

                switch usermode
                    case {'manual','debug'}
                        subplot(word_length,1,ind_position)
                        cla
                        bar(1:length(alphabet), PROB(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
                        grid on
                        grid minor
                        set(gca,'xtick',1:length(alphabet))
                        set(gca,'xticklabel',alpha_cell_array)
                        xlim([0 length(alphabet)+1])
                        title(['\rmProbability of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])
                    case 'auto'
                        % Do nothing
                end

            end

            switch usermode
                case {'manual','debug'}
                    for ind_position = 1 : word_length
                        subplot(word_length,1,ind_position)
                        ylim([0 max(PROB(:))])
                    end
                case 'auto'
                    % Do nothing
            end

            %% Value distributions for possible solutions

            VAL = interp1(Gauss.prob, Gauss.val, PROB(:));
            [val_top, ind_top] = sort(VAL, 'descend');
            [row_top, col_top] = ind2sub(size(PROB),ind_top);
            VAL = reshape(VAL, size(PROB));

            switch usermode
                case {'manual','debug'}
                    figure(2)
                        clf
                        set(gcf,'color','white')
                        pos = get(gcf,'position');
                        set(gcf,'position',[pos(1) 50 560 900])

                    for ind_position = 1 : word_length

                        % Plot the result
                        subplot(word_length,1,ind_position)
                        cla
                        bar(1:length(alphabet), VAL(:,ind_position), 'FaceColor', zeros(1,3)+0.5)
                        grid on
                        grid minor
                        set(gca,'xtick',1:length(alphabet))
                        set(gca,'xticklabel',alpha_cell_array)
                        xlim([0 length(alphabet)+1])
                        if max(VAL(:)) > 0
                            ylim([0 max(VAL(:))])
                        end
                        title(['\rmValue of ' num2str(length(DICT_SOL)) ' Valid ' num2str(word_length) '-Letter Words By Position #' num2str(ind_position) '\rm'])

                    end
                
                case 'auto'
                    % Do nothing
            end

            %% Score guesses

            Score_Gue = zeros(length(DICT_GUE),1);

            for w = 1 : length(DICT_GUE) % for each word

                for i = 1 : word_length % for each tile

                    ind_alpha = find(DICT_GUE{w}(i) == alphabet);    % alphabetical index of this tile
                    
                    if PROB(ind_alpha, i) == 1
                        % A tile that we already know is correct adds no
                        % value to any position (including its own), except
                        % indirectly
                        continue
                    end
                    
                    gain_pos    = ones(1,word_length);
                    gain_pos(i) = green_yellow_ratio;
                    
                    ind_green     = find(PROB(ind_alpha,:)==1);          % indices of green tiles of this letter
                    ind_match     = find(DICT_GUE{w}(i) == DICT_GUE{w}); % indices of tiles with this letter
                    
                    qty_green = length(ind_green); % number of green tiles of this letter
                    qty_match = length(ind_match); % number of tiles of this letter
                    qty_non_green = qty_match - qty_green;
                    qty_non_green = max([1 qty_non_green]); % enforce non-zero, non-negative
                    
                    % If we know the word contains a certain letter, we might
                    % still want to guess it elsewhere in the word. However, it
                    % might just come up yellow, telling us basically what we
                    % already knew - no new information
                    if qty_non_green > 1 % qty_green>=1
                        gain_pos = gain_pos ./ green_yellow_ratio;
                    end
                    
                    Score_Gue(w) = Score_Gue(w) + dot(VAL(ind_alpha,:), gain_pos) / qty_non_green;

                end

            end

            [~, ind_best_gue] = sort(Score_Gue,'descend');
            
            switch usermode
                case 'auto'
                    % Do nothing
                case {'manual','debug'}
                    disp(' ')
                    disp('Most valuable guesses (to advance):')
                    for i = 1 : qty_suggest
                        disp([num2str(i) '. ' DICT_GUE{ind_best_gue(i)} ' (' num2str(Score_Gue(ind_best_gue(i))) ')'])
                    end
            end

            %% Score solutions

            Score_Sol = ones(length(DICT_SOL),1);
            for w = 1 : length(DICT_SOL)
                for i = 1 : word_length
                    Score_Sol(w) = Score_Sol(w) * PROB(find(DICT_SOL{w}(i)==alphabet), i);
                end
            end

            [~, ind_best_sol] = sort(Score_Sol,'descend');
            
            switch usermode
                case 'auto'
                    % Do nothing
                case {'manual','debug'}
            
                    disp(' ')
                    disp('Most probable guesses (to win):')
                    for i = 1 : min([length(DICT_SOL) qty_suggest])
                        disp([num2str(i) '. ' DICT_SOL{ind_best_sol(i)} ' (' num2str(Score_Sol(ind_best_sol(i))) ')'])
                    end
                    disp(' ')
            end

            %% Get a guess/response pair

            switch usermode

                case {'auto', 'debug'}

                    switch length(DICT_SOL)
                        case 1
                            % We already know the solution by process of
                            % elimination, and just need to formally guess it
                            guess = DICT_SOL{:};
                        case 2
                            % Two solutions remain, we may as well pick one at
                            % random
                            guess = DICT_SOL{1}; % pick the first one
                        otherwise
                            % Three or more solutions remain, must continue
                            % advancing rather than trying to win
                            
                            % If there is a tie among the most valuable
                            % words, see if any of them are solutions, and
                            % if so pick the most probable one. Otherwise
                            % just pick the most valuable word.
                            
                            ind_top_gue = find(Score_Gue == max(Score_Gue));
                            ind_top_sol = find(Score_Sol == max(Score_Sol));
                            
                            top_gue = DICT_GUE(ind_top_gue);
                            top_sol = DICT_SOL(ind_top_sol);
                            
                            top_intersec = intersect(top_gue, top_sol);
                            
                            if ~isempty(top_intersec) % one word is both most valuable and most probable
                                guess = top_intersec{:};
                            else
                                guess = DICT_GUE{ind_best_gue(1)};
                            end
                            
                    end
                        
                    response = wordle_response(SOLUTION, guess);
                    disp([guess ' - ' response])

                case 'manual'

                    guess = input('Guess:    ','s');
                    if length(guess) ~= word_length
                        warning('Invalid length')
                        continue
                    end
                    if length(find(strcmp(DICT_GUE, guess))) ~= 1
                        warning('Invalid word')
                        continue
                    end

                    response = input('Response: ','s');
                    if length(response) ~= word_length
                        warning('Invalid length')
                        continue
                    end
                    if length(regexprep(response, '[kyg]', '')) > 0
                        warning('Invalid response, must solely contain [kyg]')
                        continue
                    end

            end

            %% Eliminate words per guess/response pair

            % Eliminate all entries from the list that are not consistent
            % with the most recent guess/response pair

            to_eliminate = zeros(length(DICT_SOL),1);

            for ind = 1 : word_length % for each letter

                letter = guess(ind);

                switch response(ind)

                    case 'k'

                        response_match = response(find(guess == letter));
                        response_non_gray = regexprep(response_match,'k','');
                        quantity_this_letter_in_sol = length(response_non_gray);
                        
                        if length(regexprep(response_match, 'k', '')) == 0 % All tile(s) of this letter were gray

                            % Eliminate all words that contain this letter
                            for w = 1 : length(DICT_SOL)
                                if length(regexprep(DICT_SOL{w}, letter, '')) ~= word_length
                                    to_eliminate(w) = 1;
                                end
                            end

                        else

                            % This is a gray tile, but there are other tile(s)
                            % of either yellow or green of the same letter. We
                            % know that the solution does not contain this
                            % letter at this position.

                            % Eliminate words that contain this letter in this position
                            for w = 1 : length(DICT_SOL)
                                if strcmp(DICT_SOL{w}(ind), letter)
                                    to_eliminate(w) = 1;
                                end
                            end
                            
                            % Since we are on a gray tile and have at least
                            % one other non-gray tile (yellow or green), we
                            % also know the total quantity of this letter
                            % in the solution, which is equal to the sum of
                            % the yellow and green tiles.
                            for w = 1 : length(DICT_SOL)
                                if length(find(DICT_SOL{w} == letter)) ~= quantity_this_letter_in_sol;
                                    to_eliminate(w) = 1;
                                end
                            end

                        end

                    case 'y'

                        % Eliminate words that contain this letter in this position
                        for w = 1 : length(DICT_SOL)
                            if strcmp(DICT_SOL{w}(ind), letter)
                                to_eliminate(w) = 1;
                            end
                        end

                        % Eliminate words that do not contain this letter in non-green non-matching tiles
                        ind_search = intersect(find(response~='g'), find(guess~=letter));
                        for w = 1 : length(DICT_SOL)
                            if length(find(DICT_SOL{w}(ind_search) == letter)) == 0
                                to_eliminate(w) = 1;
                            end
                        end

                    case 'g'

                        % Eliminate words that do not contain this letter in this position
                        for w = 1 : length(DICT_SOL)
                            if ~strcmp(DICT_SOL{w}(ind), letter)
                                to_eliminate(w) = 1;
                            end
                        end

                    otherwise
                        error('Unrecognized response')

                end

            end

            % Eliminate words
            DICT_SOL = DICT_SOL(find(~to_eliminate));
            
            switch usermode
                case 'debug'
                    drawnow
                    pause
                otherwise
                    % Do nothing
            end

        end
        
        % At this point, have either won the game or run out of possible
        % solutions

        if length(DICT_SOL) ~= 1
            warning('Guesses did not converge')
        else
            SOLS{ind_game}   = DICT_SOL{:};
            SCORES(ind_game) = ind_round;
            
            disp(' ')
            disp(['Score: ' num2str(ind_round)]);
            disp(['Mean:  ' num2str(mean(SCORES(:)))])
            disp(['Stdev: ' num2str(std(SCORES(:)))])
%             disp(['Rate:  ' num2str(round(toc/ind_game*100)/100) ' sec/game'])
            rate = toc/ind_game; % sec/game
            games_remaining = auto_game_qty - ind_game;
            time_remaining  = games_remaining * rate; % sec
            time_remaining_hh = floor(time_remaining/60^2);
            time_remaining_mm = round((time_remaining - time_remaining_hh*60^2) / 60);
            disp(['Left:  ' num2str(time_remaining_hh) 'h' num2str(time_remaining_mm) 'm'])
            disp('===========================')

        end
        
        ind_game = ind_game + 1;
        
    end
    
    diary off
    
% end













































