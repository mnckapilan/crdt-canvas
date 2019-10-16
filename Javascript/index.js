import * as Automerge from 'automerge'


export class Automerger {

    static randomNumber(thing) {
        return thing;
    }

    static initDocument() {
        return Automerge.save(Automerge.init());
    }

    // Local changes when user adds a stoke.
    // We will be sending a list of changes but this list only contains one change
    static addStroke(currentDocString, stroke) {
        currentDoc = Automerge.load(currentDocString);
        let newDoc = Automerge.change(currentDoc, currentDoc => {
            currentDoc.strokes.push(stroke);
        });
        let change = Automerge.getChanges(currentDoc, newDoc);
        return [Automerge.save(newDoc), change];
    }

    // If we are sending/receiving changes, use this.
    // May be an issue as it's only one change ? But give it a go
    static mergeIncomingChanges(currentDocString, changes) {
        currentDoc = Automerge.load(currentDocString);
        let newDoc = Automerge.applyChanges(currentDoc, changes);
        return Automerge.save(newDoc);
    }

    // Maybe add ids to every change, and pass that in as a parameter
    // so we can find it as this may not work.
    static undoRecentLocalChange(currentDocString) {
        currentDoc = Automerge.load(currentDocString);
        newDoc = Automerge.undo(currentDoc);
        return Automerge.save(newDoc);
    }

    static redoRecentLocalChange(currentDocString) {
        currentDoc = Automerge.load(currentDocString);
        newDoc = Automerge.redo(currentDoc);
        return Automerge.save(newDoc);
    }

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
};