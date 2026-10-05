"""Hand-written text for each constellation card, keyed by IAU abbreviation.

Brightest star, best viewing month and visibility range are computed by
generate.py from the star catalog.
"""

FACTS = {
    "And": dict(
        name="Andromeda", genitive="Andromedae", meaning="The Chained Princess",
        description="Andromeda was the daughter of Cepheus and Cassiopeia, chained to a sea cliff as a sacrifice to the monster Cetus until Perseus rescued her. Her brightest star, Alpheratz, doubles as a corner of the Great Square of Pegasus.",
        fun_fact="The Andromeda Galaxy (M31), about 2.5 million light-years away, is the most distant thing most people can see with the naked eye, and it is on course to merge with the Milky Way in roughly 4 to 5 billion years.",
    ),
    "Ant": dict(
        name="Antlia", genitive="Antliae", meaning="The Air Pump",
        description="A faint southern constellation created by Nicolas-Louis de Lacaille in the 1750s, honoring the air pump, one of the great scientific instruments of the age. It sits between Hydra and Vela with no star brighter than magnitude 4.",
        fun_fact="Antlia is one of 14 constellations Lacaille invented while mapping the southern sky from South Africa; nearly all of them are named after scientific or artistic tools rather than myths.",
    ),
    "Aps": dict(
        name="Apus", genitive="Apodis", meaning="The Bird of Paradise",
        description="A small, faint constellation close to the south celestial pole, introduced from the observations of Dutch navigators Pieter Keyser and Frederick de Houtman in the 1590s.",
        fun_fact="Its name comes from the Greek apous, \"footless\": bird-of-paradise skins reached Europe with the feet removed, so people believed the birds had no feet and never landed.",
    ),
    "Aqr": dict(
        name="Aquarius", genitive="Aquarii", meaning="The Water Bearer",
        description="A zodiac constellation showing a youth, often identified as Ganymede, pouring water from a jar. It lies in a watery region of sky called \"the Sea\" alongside Cetus, Pisces, Eridanus and Piscis Austrinus.",
        fun_fact="Aquarius holds the Helix Nebula, one of the closest planetary nebulae to Earth, nicknamed the \"Eye of God\", and the Eta Aquariid meteor shower, made of debris from Halley's Comet.",
    ),
    "Aql": dict(
        name="Aquila", genitive="Aquilae", meaning="The Eagle",
        description="The eagle that carried Zeus's thunderbolts. Its brightest star, Altair, forms one corner of the Summer Triangle with Vega and Deneb.",
        fun_fact="Altair spins once every 9 hours or so, so fast that it bulges at the equator, where it is about 20% wider than it is pole to pole.",
    ),
    "Ara": dict(
        name="Ara", genitive="Arae", meaning="The Altar",
        description="The altar on which the Olympian gods swore allegiance before their war against the Titans. In some tellings, the Milky Way above it is the altar's rising smoke.",
        fun_fact="Ara contains NGC 6397, one of the two closest globular clusters to Earth, a ball of ancient stars about 7,800 light-years away.",
    ),
    "Ari": dict(
        name="Aries", genitive="Arietis", meaning="The Ram",
        description="A zodiac constellation representing the ram with the golden fleece that rescued Phrixus; Jason and the Argonauts later sailed to recover the fleece.",
        fun_fact="About 2,000 years ago the Sun stood in Aries at the March equinox, so that point is still called the \"First Point of Aries\", even though Earth's wobble has since carried it into Pisces.",
    ),
    "Aur": dict(
        name="Auriga", genitive="Aurigae", meaning="The Charioteer",
        description="A charioteer, often identified with Erichthonius, inventor of the four-horse chariot, drawn carrying a she-goat and her kids. Its bright stars form a large pentagon high in winter skies.",
        fun_fact="Capella, \"the little she-goat\", looks like one star but is two yellow giants orbiting each other every 104 days, with a pair of faint red dwarfs far off.",
    ),
    "Boo": dict(
        name="Boötes", genitive="Boötis", meaning="The Herdsman",
        description="A herdsman driving the bears of Ursa Major around the pole. Find it by following the curve of the Big Dipper's handle: \"arc to Arcturus\".",
        fun_fact="In 1933 starlight from Arcturus, caught by a telescope and photocell, switched on the lights of the Chicago World's Fair. The light was thought to have left the star around the time of Chicago's previous fair in 1893.",
    ),
    "Cae": dict(
        name="Caelum", genitive="Caeli", meaning="The Chisel",
        description="One of Lacaille's 1750s inventions, originally called Caelum Scalptorium, \"the engraver's chisel\". It is a tiny, dim pattern squeezed between Columba and Eridanus.",
        fun_fact="Caelum has no myth at all and no star brighter than magnitude 4.4, making it one of the most overlooked constellations in the sky.",
    ),
    "Cam": dict(
        name="Camelopardalis", genitive="Camelopardalis", meaning="The Giraffe",
        description="A large but faint northern constellation introduced by Petrus Plancius in 1612. Its name comes from the Greek for \"camel-leopard\", the old name for a giraffe.",
        fun_fact="It contains Kemble's Cascade, a straight line of about 20 stars that looks like a waterfall tumbling into a small star cluster through binoculars.",
    ),
    "Cnc": dict(
        name="Cancer", genitive="Cancri", meaning="The Crab",
        description="The faintest zodiac constellation: the crab Hera sent to nip at Heracles while he fought the Hydra, crushed under the hero's foot.",
        fun_fact="It holds the Beehive Cluster (M44), a naked-eye smudge of stars, and gave its name to the Tropic of Cancer because the Sun stood here at the June solstice about 2,000 years ago.",
    ),
    "CVn": dict(
        name="Canes Venatici", genitive="Canum Venaticorum", meaning="The Hunting Dogs",
        description="The two dogs held on a leash by Boötes the herdsman, created by Johannes Hevelius in 1687 from faint stars beneath the Big Dipper's handle.",
        fun_fact="It contains the Whirlpool Galaxy (M51), the first galaxy in which spiral arms were seen, sketched by Lord Rosse in 1845. Its brightest star, Cor Caroli, honors King Charles of England.",
    ),
    "CMa": dict(
        name="Canis Major", genitive="Canis Majoris", meaning="The Great Dog",
        description="Orion's larger hunting dog, trotting at his heels. It holds Sirius, the brightest star in the night sky, only 8.6 light-years away.",
        fun_fact="In ancient Egypt Sirius rising before dawn announced the Nile flood, and the \"dog days\" of summer are named for the Dog Star's appearance with the Sun.",
    ),
    "CMi": dict(
        name="Canis Minor", genitive="Canis Minoris", meaning="The Lesser Dog",
        description="Orion's smaller dog, which is mostly just two stars: Procyon and Gomeisa. Procyon forms the Winter Triangle with Sirius and Betelgeuse.",
        fun_fact="Procyon means \"before the dog\" in Greek, because from mid-northern latitudes it rises shortly before Sirius, the Dog Star.",
    ),
    "Cap": dict(
        name="Capricornus", genitive="Capricorni", meaning="The Sea Goat",
        description="A zodiac constellation shaped like a goat with a fish's tail, linked to the god Pan, who leapt into the Nile and turned half-fish to escape the monster Typhon.",
        fun_fact="The Tropic of Capricorn is named after it because the Sun stood in Capricornus at the December solstice about 2,000 years ago. Today it is in Sagittarius on that date.",
    ),
    "Car": dict(
        name="Carina", genitive="Carinae", meaning="The Keel",
        description="The keel of Jason's ship Argo Navis, a giant ancient constellation that Lacaille split into Carina, Puppis and Vela. It holds Canopus, the second-brightest star in the night sky.",
        fun_fact="The monster star system Eta Carinae erupted in the 1840s and briefly became the second-brightest star in the sky, throwing off a glowing double cloud called the Homunculus Nebula.",
    ),
    "Cas": dict(
        name="Cassiopeia", genitive="Cassiopeiae", meaning="The Queen",
        description="The vain queen of Aethiopia who boasted that she was more beautiful than the sea nymphs. Her five bright stars form an easy \"W\" that circles the north pole, upside down half the time.",
        fun_fact="In 1572 Tycho Brahe watched a \"new star\" blaze up in Cassiopeia. That supernova proved the heavens could change and helped overturn the ancient idea of fixed, perfect skies.",
    ),
    "Cen": dict(
        name="Centaurus", genitive="Centauri", meaning="The Centaur",
        description="A large southern constellation, often identified as Chiron, the wise centaur who tutored heroes like Achilles and Jason. Its two brightest stars point toward the Southern Cross.",
        fun_fact="Alpha Centauri is the nearest star system to the Sun, 4.4 light-years away, and its faint companion Proxima Centauri is the closest star of all. Centaurus also holds Omega Centauri, the Milky Way's biggest globular cluster.",
    ),
    "Cep": dict(
        name="Cepheus", genitive="Cephei", meaning="The King",
        description="King of Aethiopia, husband of Cassiopeia and father of Andromeda. Its stars trace a simple house with a pointed roof near the north celestial pole.",
        fun_fact="Delta Cephei is the prototype Cepheid variable: its pulsation period reveals its true brightness, the cosmic yardstick Henrietta Leavitt found and Edwin Hubble used to measure distances to other galaxies.",
    ),
    "Cet": dict(
        name="Cetus", genitive="Ceti", meaning="The Sea Monster",
        description="The sea monster Poseidon sent to devour Andromeda, turned to stone by Perseus with Medusa's head. It is the fourth-largest constellation.",
        fun_fact="Its star Mira, \"the wonderful\", was the first variable star recognized (in 1596). Over about 11 months it swings from easily visible to far too faint to see without a telescope.",
    ),
    "Cha": dict(
        name="Chamaeleon", genitive="Chamaeleontis", meaning="The Chameleon",
        description="A small, faint constellation near the south celestial pole, introduced from the observations of Dutch navigators Keyser and de Houtman in the 1590s.",
        fun_fact="It hides the Chamaeleon dark clouds, one of the nearest star-forming regions to the Sun, where hundreds of newborn stars are still emerging from dust.",
    ),
    "Cir": dict(
        name="Circinus", genitive="Circini", meaning="The Compass",
        description="One of Lacaille's instruments: a drafting compass, the kind used to draw circles. It is a tiny constellation tucked right beside Alpha Centauri.",
        fun_fact="The Circinus Galaxy, one of the closest galaxies with a feeding black hole, hid behind the Milky Way's dust until astronomers found it in 1977.",
    ),
    "Col": dict(
        name="Columba", genitive="Columbae", meaning="The Dove",
        description="Introduced by Petrus Plancius in 1592 to represent the dove Noah sent from the ark, which returned with an olive branch. It sits just south of Lepus.",
        fun_fact="Mu Columbae is a runaway star. It and AE Aurigae were flung apart about 2.5 million years ago in a close encounter in the Orion region, and they are still racing away in opposite directions.",
    ),
    "Com": dict(
        name="Coma Berenices", genitive="Comae Berenices", meaning="Berenice's Hair",
        description="Queen Berenice II of Egypt cut off her hair as an offering for her husband's safe return from war. When it vanished from the temple, the court astronomer declared that the gods had placed it in the sky. It is the only constellation named after a historical person.",
        fun_fact="Behind it lies the Coma Cluster of thousands of galaxies. In 1933 Fritz Zwicky noticed that its galaxies move too fast for their visible mass, the first evidence of dark matter.",
    ),
    "CrA": dict(
        name="Corona Australis", genitive="Coronae Australis", meaning="The Southern Crown",
        description="A graceful arc of faint stars below Sagittarius, one of the 48 constellations listed by Ptolemy. It is usually seen as a wreath or crown.",
        fun_fact="The dark cloud near R Coronae Australis is one of the closest star nurseries to Earth, about 400 light-years away, full of stars only a few million years old.",
    ),
    "CrB": dict(
        name="Corona Borealis", genitive="Coronae Borealis", meaning="The Northern Crown",
        description="The crown Dionysus gave to Ariadne on their wedding day, later set among the stars. Seven stars form a neat horseshoe between Boötes and Hercules.",
        fun_fact="It is home to T Coronae Borealis, the \"Blaze Star\", a recurrent nova that flared to naked-eye brightness in 1866 and 1946. Astronomers worldwide have been watching for its next outburst.",
    ),
    "Crv": dict(
        name="Corvus", genitive="Corvi", meaning="The Crow",
        description="Apollo sent his crow to fetch water in a cup but it dawdled, then blamed a water snake. Apollo set the crow, the cup (Crater) and the snake (Hydra) in the sky, with the thirsty crow forever kept from the cup.",
        fun_fact="The Antennae Galaxies in Corvus are two galaxies in mid-collision, flinging out long tails of stars that look like an insect's antennae.",
    ),
    "Crt": dict(
        name="Crater", genitive="Crateris", meaning="The Cup",
        description="Apollo's cup, riding on the back of Hydra next to Corvus the crow, which was never allowed to drink from it. It is a faint goblet shape south of Leo.",
        fun_fact="Crater's brightest star is Delta, not Alpha. Bayer's Greek letters don't always follow brightness order.",
    ),
    "Cru": dict(
        name="Crux", genitive="Crucis", meaning="The Southern Cross",
        description="The smallest of the 88 constellations, yet one of the most famous. Ptolemy counted its stars as part of Centaurus. Its long axis points toward the south celestial pole, which made it a navigator's guide.",
        fun_fact="The Southern Cross appears on the flags of Australia, New Zealand, Brazil, Samoa and Papua New Guinea. Right beside it lies the Coalsack, a dark cloud that blots out the Milky Way.",
    ),
    "Cyg": dict(
        name="Cygnus", genitive="Cygni", meaning="The Swan",
        description="A swan, often Zeus in disguise, flying down the Milky Way. Its bright stars form the Northern Cross, and Deneb at its tail is a corner of the Summer Triangle.",
        fun_fact="Cygnus X-1, discovered in the 1960s, became the first object widely accepted as a black hole. It is pulling gas off a giant blue companion star.",
    ),
    "Del": dict(
        name="Delphinus", genitive="Delphini", meaning="The Dolphin",
        description="The dolphin that persuaded the sea nymph Amphitrite to marry Poseidon, or that saved the poet Arion. Its small diamond of stars is nicknamed \"Job's Coffin\".",
        fun_fact="Its stars Sualocin and Rotanev spell \"Nicolaus Venator\" backward, the Latin name of Niccolò Cacciatore, an astronomer's assistant who slipped his own name into an 1814 star catalog.",
    ),
    "Dor": dict(
        name="Dorado", genitive="Doradus", meaning="The Dolphinfish",
        description="A dolphinfish (mahi-mahi), introduced from the observations of Dutch navigators Keyser and de Houtman in the 1590s. It contains most of the Large Magellanic Cloud.",
        fun_fact="In 1987 a star in the Large Magellanic Cloud exploded as Supernova 1987A, the closest supernova seen since the invention of the telescope, visible to the naked eye from the Southern Hemisphere.",
    ),
    "Dra": dict(
        name="Draco", genitive="Draconis", meaning="The Dragon",
        description="Ladon, the dragon that guarded the golden apples of the Hesperides until Heracles slew it. Its long body winds between the Big and Little Dippers.",
        fun_fact="Its star Thuban was the North Star around 2800 BC, when Egyptians were building the pyramids. Earth's slow wobble has since moved the pole toward Polaris.",
    ),
    "Equ": dict(
        name="Equuleus", genitive="Equulei", meaning="The Little Horse",
        description="A foal's head peeking out beside Pegasus, one of the 48 constellations listed by Ptolemy. It is sometimes said to be Celeris, brother of Pegasus.",
        fun_fact="Equuleus is the second-smallest constellation of all; only Crux, the Southern Cross, is smaller.",
    ),
    "Eri": dict(
        name="Eridanus", genitive="Eridani", meaning="The River",
        description="A celestial river meandering from Orion's foot far into the southern sky, often linked to the river where Phaethon fell after losing control of the Sun's chariot. It is the sixth-largest constellation.",
        fun_fact="Achernar, at the river's end, spins so fast that it is one of the least spherical stars known, about 35% wider at the equator than pole to pole.",
    ),
    "For": dict(
        name="Fornax", genitive="Fornacis", meaning="The Furnace",
        description="One of Lacaille's 1750s inventions, originally Fornax Chemica, the chemical furnace used in laboratory experiments. It is a faint patch inside a loop of Eridanus.",
        fun_fact="The Hubble Ultra Deep Field was taken in Fornax. A patch of sky smaller than a grain of sand held at arm's length turned out to contain about 10,000 galaxies.",
    ),
    "Gem": dict(
        name="Gemini", genitive="Geminorum", meaning="The Twins",
        description="The twins Castor and Pollux, sons of Leda. When mortal Castor died, immortal Pollux shared his immortality so they could stay together. Their two bright stars mark the twins' heads.",
        fun_fact="Castor looks like one star but is a system of six: three pairs of stars orbiting each other. The December Geminid meteor shower comes from an asteroid, 3200 Phaethon, rather than a comet.",
    ),
    "Gru": dict(
        name="Grus", genitive="Gruis", meaning="The Crane",
        description="A long-necked crane, introduced from the observations of Dutch navigators Keyser and de Houtman in the 1590s. It stands just south of Piscis Austrinus.",
        fun_fact="Its two brightest stars make a lovely color contrast even to the naked eye: Alnair is blue-white, while Beta Gruis is a cool red giant.",
    ),
    "Her": dict(
        name="Hercules", genitive="Herculis", meaning="The Hero",
        description="The Greek hero Heracles, drawn kneeling upside down with one foot on Draco's head. Four of its stars form the \"Keystone\". It is the fifth-largest constellation.",
        fun_fact="In 1974 the Arecibo radio telescope beamed a message toward the Great Globular Cluster M13 in Hercules. It will arrive in about 25,000 years.",
    ),
    "Hor": dict(
        name="Horologium", genitive="Horologii", meaning="The Pendulum Clock",
        description="One of Lacaille's 1750s inventions, honoring the pendulum clock that made precise astronomical timing possible. It is a faint line of stars near Eridanus.",
        fun_fact="Far beyond its faint stars lies the Horologium-Reticulum Supercluster, one of the largest known structures in the nearby universe.",
    ),
    "Hya": dict(
        name="Hydra", genitive="Hydrae", meaning="The Water Snake",
        description="The largest of the 88 constellations, a sea serpent sprawling more than 100° across the sky, with Corvus and Crater riding on its back. It is often linked to the many-headed Hydra slain by Heracles.",
        fun_fact="Its brightest star, Alphard, means \"the solitary one\" in Arabic, because it shines alone in an otherwise empty stretch of sky.",
    ),
    "Hyi": dict(
        name="Hydrus", genitive="Hydri", meaning="The Lesser Water Snake",
        description="A small water snake near the south celestial pole, introduced by Keyser and de Houtman in the 1590s. It winds between the Large and Small Magellanic Clouds.",
        fun_fact="Beta Hydri, only 24 light-years away, is a preview of the Sun's future: a slightly older Sun-like star that is starting to swell into a subgiant.",
    ),
    "Ind": dict(
        name="Indus", genitive="Indi", meaning="The Indian",
        description="Introduced by Keyser and de Houtman in the 1590s, depicting an Indigenous person of the lands Dutch traders visited, armed with arrows and a spear.",
        fun_fact="Epsilon Indi, just 12 light-years away, has two brown dwarfs and a cold giant planet; JWST photographed the planet directly in 2024.",
    ),
    "Lac": dict(
        name="Lacerta", genitive="Lacertae", meaning="The Lizard",
        description="A small zigzag of faint stars wedged between Cygnus and Andromeda, created by Johannes Hevelius in 1687.",
        fun_fact="BL Lacertae was catalogued as a variable star but turned out to be the blazing core of a distant galaxy, which gave its name to a whole class of objects called BL Lac objects.",
    ),
    "Leo": dict(
        name="Leo", genitive="Leonis", meaning="The Lion",
        description="The Nemean lion slain by Heracles as his first labor. A backward question mark of stars, the Sickle, outlines its head and mane, with Regulus at the lion's heart.",
        fun_fact="The Leonid meteors radiate from Leo every November; in 1833 they produced a storm of tens of thousands of meteors per hour that kick-started the study of meteor showers.",
    ),
    "LMi": dict(
        name="Leo Minor", genitive="Leonis Minoris", meaning="The Lesser Lion",
        description="A faint little lion cub tucked between Leo and Ursa Major, created by Johannes Hevelius in 1687.",
        fun_fact="Leo Minor has a Beta star but no Alpha: when Francis Baily assigned Greek letters in 1845 he gave out Beta and skipped Alpha entirely.",
    ),
    "Lep": dict(
        name="Lepus", genitive="Leporis", meaning="The Hare",
        description="A hare crouching at Orion's feet, forever chased by the hunter and his dogs. It is one of Ptolemy's 48 constellations.",
        fun_fact="Hind's Crimson Star (R Leporis) is one of the reddest stars in the sky; its discoverer described it as looking \"like a drop of blood on a black field\".",
    ),
    "Lib": dict(
        name="Libra", genitive="Librae", meaning="The Scales",
        description="The scales of justice, the only zodiac sign that is an object rather than a creature. In earlier times its stars formed the claws of Scorpius.",
        fun_fact="Its two brightest stars are Zubenelgenubi and Zubeneschamali, Arabic for \"the southern claw\" and \"the northern claw\", left over from when Libra was part of the scorpion.",
    ),
    "Lup": dict(
        name="Lupus", genitive="Lupi", meaning="The Wolf",
        description="An ancient constellation showing a wild animal, later called a wolf, held on a spear by the Centaur next door.",
        fun_fact="SN 1006, the brightest supernova in recorded history, blazed in Lupus in the year 1006. It was bright enough to read by at night and was recorded in China, Egypt, Iraq, Japan and Europe.",
    ),
    "Lyn": dict(
        name="Lynx", genitive="Lyncis", meaning="The Lynx",
        description="A long, faint chain of stars between Ursa Major and Auriga, created by Johannes Hevelius in 1687.",
        fun_fact="Hevelius named it Lynx because, he said, you'd need the eyes of a lynx to see it at all.",
    ),
    "Lyr": dict(
        name="Lyra", genitive="Lyrae", meaning="The Lyre",
        description="The lyre of Orpheus, whose music could charm rocks and rivers. Its brilliant star Vega is one corner of the Summer Triangle.",
        fun_fact="Vega was the first star after the Sun to be photographed, in 1850. Thanks to Earth's wobble it was the North Star around 12,000 BC and will be again around AD 13,700.",
    ),
    "Men": dict(
        name="Mensa", genitive="Mensae", meaning="The Table Mountain",
        description="Lacaille named it for Table Mountain above Cape Town, where he observed the southern sky in the 1750s. Part of the Large Magellanic Cloud spills into it, like the cloud that often caps the real mountain.",
        fun_fact="Mensa is the faintest of all 88 constellations, with its brightest star only magnitude 5.1, and the only one named after a place on Earth.",
    ),
    "Mic": dict(
        name="Microscopium", genitive="Microscopii", meaning="The Microscope",
        description="One of Lacaille's 1750s instrument constellations, a faint patch south of Capricornus honoring the early compound microscope.",
        fun_fact="AU Microscopii, a young red dwarf 32 light-years away, has an edge-on dust disk and young planets, so astronomers can watch a planetary system in the making.",
    ),
    "Mon": dict(
        name="Monoceros", genitive="Monocerotis", meaning="The Unicorn",
        description="A faint unicorn introduced by Petrus Plancius in 1612, filling the middle of the Winter Triangle formed by Betelgeuse, Sirius and Procyon.",
        fun_fact="In 2002 the star V838 Monocerotis flared up, and its \"light echo\" spreading through surrounding dust made one of Hubble's most famous image sequences.",
    ),
    "Mus": dict(
        name="Musca", genitive="Muscae", meaning="The Fly",
        description="A small southern constellation just below the Southern Cross, introduced by Keyser and de Houtman in the 1590s.",
        fun_fact="It is the only insect in today's sky. A northern fly, Musca Borealis, once buzzed near Aries but was dropped from the official list.",
    ),
    "Nor": dict(
        name="Norma", genitive="Normae", meaning="The Carpenter's Square",
        description="One of Lacaille's 1750s instrument constellations, representing a carpenter's set square, lying in the Milky Way between Lupus and Ara.",
        fun_fact="Norma has no Alpha or Beta star: when the IAU redrew constellation borders, its original Alpha and Beta ended up inside Scorpius.",
    ),
    "Oct": dict(
        name="Octans", genitive="Octantis", meaning="The Octant",
        description="Lacaille's navigational octant, an instrument for measuring the angle of stars above the horizon. It contains the south celestial pole.",
        fun_fact="The southern pole star, Sigma Octantis, is barely visible at magnitude 5.4, so southern navigators traditionally found south using the Southern Cross instead.",
    ),
    "Oph": dict(
        name="Ophiuchus", genitive="Ophiuchi", meaning="The Serpent Bearer",
        description="Asclepius, the healer so skilled he could raise the dead, shown wrestling a great snake that splits Serpens into two halves.",
        fun_fact="The Sun passes through Ophiuchus every year in early December, making it the \"13th zodiac constellation\" astrologers leave out. Kepler's Supernova of 1604, the last naked-eye supernova seen in our galaxy, appeared here.",
    ),
    "Ori": dict(
        name="Orion", genitive="Orionis", meaning="The Hunter",
        description="The great hunter, with his three-star belt, red Betelgeuse on his shoulder and blue-white Rigel at his foot. He straddles the celestial equator, so he can be seen from every inhabited place on Earth.",
        fun_fact="The fuzzy \"star\" in Orion's sword is the Orion Nebula, a stellar nursery about 1,300 light-years away. Betelgeuse surprised astronomers by fading dramatically in 2019-2020, the \"Great Dimming\".",
    ),
    "Pav": dict(
        name="Pavo", genitive="Pavonis", meaning="The Peacock",
        description="A peacock, introduced by Keyser and de Houtman in the 1590s. It is often linked to Hera's sacred bird, whose tail held the hundred eyes of Argus.",
        fun_fact="Its brightest star is officially named \"Peacock\", a name invented in the 1930s for the Royal Air Force's air navigation almanac.",
    ),
    "Peg": dict(
        name="Pegasus", genitive="Pegasi", meaning="The Winged Horse",
        description="The winged horse that sprang from Medusa's neck when Perseus beheaded her. Its body is the Great Square of Pegasus, a huge box of four stars in autumn skies.",
        fun_fact="51 Pegasi b, found in 1995, was the first planet discovered orbiting a Sun-like star, a discovery that won Michel Mayor and Didier Queloz the 2019 Nobel Prize in Physics.",
    ),
    "Per": dict(
        name="Perseus", genitive="Persei", meaning="The Hero",
        description="The hero who beheaded Medusa and rescued Andromeda from the sea monster. He holds Medusa's head, marked by the star Algol.",
        fun_fact="Algol, the \"Demon Star\", visibly dims every 2.87 days when a companion star passes in front of it. Each August the Perseid meteor shower radiates from this constellation.",
    ),
    "Phe": dict(
        name="Phoenix", genitive="Phoenicis", meaning="The Phoenix",
        description="The mythical bird reborn from its own ashes, introduced by Keyser and de Houtman in the 1590s. It lies near Achernar in the southern sky.",
        fun_fact="The Phoenix Cluster, a galaxy cluster billions of light-years beyond it, has a central galaxy forming new stars at hundreds of times the Milky Way's rate.",
    ),
    "Pic": dict(
        name="Pictor", genitive="Pictoris", meaning="The Painter's Easel",
        description="One of Lacaille's 1750s inventions, originally \"le Chevalet et la Palette\", the painter's easel and palette. It lies near the brilliant star Canopus.",
        fun_fact="Beta Pictoris was one of the first stars found with a disk of planet-forming dust (in 1984), and at least two giant planets have since been photographed around it.",
    ),
    "Psc": dict(
        name="Pisces", genitive="Piscium", meaning="The Fishes",
        description="Two fish tied together by a cord: Aphrodite and Eros, who turned into fish and leapt into a river to escape the monster Typhon. It is a large but faint zodiac constellation.",
        fun_fact="The March equinox point now lies in Pisces and is slowly drifting toward Aquarius, where it will arrive in about six centuries: the astronomical \"Age of Aquarius\".",
    ),
    "PsA": dict(
        name="Piscis Austrinus", genitive="Piscis Austrini", meaning="The Southern Fish",
        description="A fish drinking the stream of water poured by Aquarius. Its bright star Fomalhaut sits alone in a dim autumn sky.",
        fun_fact="Fomalhaut has a vast dusty ring. \"Fomalhaut b\", once celebrated as a directly photographed planet, now seems to have been an expanding cloud of debris from a collision.",
    ),
    "Pup": dict(
        name="Puppis", genitive="Puppis", meaning="The Stern",
        description="The stern, or poop deck, of Jason's ship Argo Navis, which Lacaille split into Carina, Puppis and Vela. The Milky Way runs through it, rich with star clusters.",
        fun_fact="Because the ship was split up, Puppis has no Alpha or Beta star. Its brightest is Zeta Puppis (Naos), one of the hottest and most luminous stars visible to the naked eye.",
    ),
    "Pyx": dict(
        name="Pyxis", genitive="Pyxidis", meaning="The Mariner's Compass",
        description="One of Lacaille's 1750s inventions, a ship's magnetic compass placed beside the old ship Argo Navis.",
        fun_fact="T Pyxidis is a recurrent nova that has erupted several times since 1890, most recently in 2011.",
    ),
    "Ret": dict(
        name="Reticulum", genitive="Reticuli", meaning="The Reticle",
        description="Lacaille's tribute to the reticle, the grid of fine crosshairs in a telescope eyepiece that he used to measure star positions.",
        fun_fact="Zeta Reticuli, a pair of Sun-like stars 39 light-years away, became famous in UFO lore through the 1961 Betty and Barney Hill abduction story.",
    ),
    "Sge": dict(
        name="Sagitta", genitive="Sagittae", meaning="The Arrow",
        description="An arrow, perhaps the one Heracles shot at the eagle tormenting Prometheus. It is a small, distinct arrow shape between Aquila and Cygnus.",
        fun_fact="Sagitta is the third-smallest constellation, yet it is one of Ptolemy's original 48, because its sharp arrow shape is easy to spot even in the Milky Way.",
    ),
    "Sgr": dict(
        name="Sagittarius", genitive="Sagittarii", meaning="The Archer",
        description="A centaur archer aiming at the heart of Scorpius, marked by Antares. Its brightest stars form a Teapot, with the Milky Way rising like steam from the spout.",
        fun_fact="The center of the Milky Way lies in Sagittarius, home of Sagittarius A*, a black hole of 4 million Suns that the Event Horizon Telescope photographed in 2022.",
    ),
    "Sco": dict(
        name="Scorpius", genitive="Scorpii", meaning="The Scorpion",
        description="The scorpion that killed Orion. The two were placed on opposite sides of the sky, so one sets as the other rises. Red Antares marks its heart.",
        fun_fact="Antares means \"rival of Mars\" because its red color matches the planet's. It is a red supergiant roughly 700 times wider than the Sun.",
    ),
    "Scl": dict(
        name="Sculptor", genitive="Sculptoris", meaning="The Sculptor",
        description="One of Lacaille's 1750s inventions, originally \"l'Atelier du Sculpteur\", the sculptor's studio. It is a faint region south of Cetus.",
        fun_fact="The south galactic pole lies in Sculptor, so we look straight out of the Milky Way's disk here, toward the bright Sculptor Galaxy (NGC 253) and many more.",
    ),
    "Sct": dict(
        name="Scutum", genitive="Scuti", meaning="The Shield",
        description="Created by Johannes Hevelius in 1684 as Scutum Sobiescianum, Sobieski's shield, honoring King John III Sobieski's victory at the Battle of Vienna.",
        fun_fact="Scutum and Coma Berenices are the only constellations that honor real people. Scutum contains the Wild Duck Cluster (M11) and UY Scuti, one of the largest stars known.",
    ),
    "Ser": dict(
        name="Serpens", genitive="Serpentis", meaning="The Serpent",
        description="The great snake held by Ophiuchus, and the only constellation split into two separate pieces: Serpens Caput (the head) and Serpens Cauda (the tail), on either side of the serpent bearer.",
        fun_fact="The Eagle Nebula in Serpens Cauda contains the \"Pillars of Creation\", towers of gas and dust photographed by Hubble in 1995 and again by JWST in 2022.",
    ),
    "Sex": dict(
        name="Sextans", genitive="Sextantis", meaning="The Sextant",
        description="A faint constellation south of Regulus, created by Johannes Hevelius in 1687 and named after the astronomical sextant he used to measure star positions.",
        fun_fact="Hevelius created Sextans in memory of the instruments he lost when a fire destroyed his observatory in Danzig in 1679.",
    ),
    "Tau": dict(
        name="Taurus", genitive="Tauri", meaning="The Bull",
        description="Zeus disguised as a white bull to carry off Europa. Red Aldebaran is the bull's eye, the V-shaped Hyades cluster its face, and the Pleiades ride on its shoulder.",
        fun_fact="The Crab Nebula is the wreck of a supernova that Chinese astronomers saw in 1054, bright enough to see in daylight for 23 days. At its heart, a pulsar spins 30 times a second.",
    ),
    "Tel": dict(
        name="Telescopium", genitive="Telescopii", meaning="The Telescope",
        description="One of Lacaille's 1750s instrument constellations, honoring the telescope. It is a faint patch south of Sagittarius.",
        fun_fact="Lacaille's telescope originally stretched into Sagittarius, Scorpius and Ophiuchus. Later astronomers handed those stars back, shrinking it to the dim remnant we have today.",
    ),
    "Tri": dict(
        name="Triangulum", genitive="Trianguli", meaning="The Triangle",
        description="A small triangle of stars between Andromeda and Aries, one of Ptolemy's 48 constellations. The Greeks saw it as the Nile Delta or the island of Sicily.",
        fun_fact="The Triangulum Galaxy (M33), about 3 million light-years away, is one of the most distant things the naked eye can see under very dark skies.",
    ),
    "TrA": dict(
        name="Triangulum Australe", genitive="Trianguli Australis", meaning="The Southern Triangle",
        description="A bright, compact triangle in the southern Milky Way near Alpha Centauri, introduced by Keyser and de Houtman in the 1590s.",
        fun_fact="It outshines its northern namesake: all three corner stars are brighter than magnitude 3, while Triangulum's brightest star is only magnitude 3.0.",
    ),
    "Tuc": dict(
        name="Tucana", genitive="Tucanae", meaning="The Toucan",
        description="A toucan, introduced by Keyser and de Houtman in the 1590s, holding the Small Magellanic Cloud in its region of sky.",
        fun_fact="47 Tucanae is so bright a globular cluster, with millions of stars, that it was first catalogued as a star and still carries a star-style designation.",
    ),
    "UMa": dict(
        name="Ursa Major", genitive="Ursae Majoris", meaning="The Great Bear",
        description="The nymph Callisto, turned into a bear. Its seven brightest stars form the Big Dipper, or Plough, and the two stars at the end of the bowl point to Polaris.",
        fun_fact="Mizar and Alcor in the Dipper's handle were a traditional eyesight test. Mizar was also the first double star seen through a telescope, around 1617.",
    ),
    "UMi": dict(
        name="Ursa Minor", genitive="Ursae Minoris", meaning="The Little Bear",
        description="The Little Dipper, with Polaris, the North Star, at the tip of its handle less than a degree from the north celestial pole.",
        fun_fact="Polaris won't always be the North Star. Earth's wobble brings it closest to the pole around 2100, then Errai in Cepheus takes over around AD 4000 and Vega around AD 14,000.",
    ),
    "Vel": dict(
        name="Vela", genitive="Velorum", meaning="The Sails",
        description="The sails of Jason's ship Argo Navis, which Lacaille split into Carina, Puppis and Vela. Two of its stars help form the \"False Cross\", often mistaken for the Southern Cross.",
        fun_fact="The Vela Pulsar, left by a supernova about 11,000 years ago, spins about 11 times every second and sits inside a huge glowing shell of supernova debris.",
    ),
    "Vir": dict(
        name="Virgo", genitive="Virginis", meaning="The Maiden",
        description="The second-largest constellation and the largest in the zodiac: a maiden holding an ear of wheat, marked by the bright star Spica, often identified with Demeter or Astraea.",
        fun_fact="It points toward the Virgo Cluster of over a thousand galaxies, including M87, whose central black hole was the first ever photographed, in 2019.",
    ),
    "Vol": dict(
        name="Volans", genitive="Volantis", meaning="The Flying Fish",
        description="A flying fish, introduced by Keyser and de Houtman in the 1590s after sailors saw the fish gliding over tropical seas.",
        fun_fact="Old star atlases show Volans fleeing the jaws of Dorado, the dolphinfish next door, just as real dolphinfish hunt flying fish.",
    ),
    "Vul": dict(
        name="Vulpecula", genitive="Vulpeculae", meaning="The Little Fox",
        description="Created by Johannes Hevelius in 1687 as Vulpecula cum Ansere, the little fox with a goose in its jaws. It lies in the Milky Way just south of Cygnus.",
        fun_fact="The first pulsar ever found, discovered by Jocelyn Bell Burnell in 1967, is in Vulpecula; its regular pulses earned it the joke nickname LGM-1, for \"Little Green Men\".",
    ),
}
