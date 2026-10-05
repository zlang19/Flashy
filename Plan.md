# Plan

## Goal
A flashcard IOS app

## Details
* Daily set of flashcards choosen to review
* Flashcard flow: show image and or text, "Reveal" button, reveal details, "Next" button, asks for performance (good bad okay). On to next card
* Spaced repetition: days till card needs to be reviewed again is determined by performance. Bad will result in a shorter period of time tile card resurfaces, okay is the same duration of time, good increases period
* Badge notification on app to show number of cards remainng to be reviewed that day
* Flashcards are to be pulled from this projects public git repository
* Flashcards are stored in a standard format, preferrably markdown
* Flashcard storage structure will follow flashcards/<category>/<flashcard_name>/<flashcard.md> + support images
* New cards are scanned for when app is opened
* Supports method of freely reviewing all flashcards. can select the category or find a specific card