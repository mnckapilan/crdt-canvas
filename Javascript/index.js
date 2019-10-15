import * as Automerge from 'automerge'

export class Synchronizer {
    static randomNumber() {
        return Math.floor(Math.random() * 100);
    }

    static synchronise() {
        /* */

     /* Case 1: Everyone online drawing
        user1 makes a change and sends changes to all other users
        user2,3.. receive change and apply change to their document
        using Automerge.applyChange()
     */
    
     /* Case 2: Someone drops and everyone else remains
         They hold a local copy of doc and all changes made, they
        can carry on editing offline and adding to doc.
        When the user comes back online, send all their changes 
        and request everyone else's changes.
        */
    /* Case 3: Everyone drops 
    */
    }
};