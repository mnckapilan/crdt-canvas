import * as Automerge from 'automerge'

var cheekyGlobalVariable = Automerge.from({strokes: {}});

export class Automerger {

    static randomNumber() {
        // console.log("random number generated");
        return Math.floor(Math.random() * 100);
    }

    static initDocument() {
        return Automerge.save(Automerge.from({ strokes: [] }));
    }

    // Local changes when user adds a stoke.
    // We will be sending a list of changes but this list only contains one change

    static addChange(changeString) {
        var change = JSON.parse(changeString);
        var type = change.type;
        if (type === "ADD_POINT") {
          var nDoc = Automerge.change(cheekyGlobalVariable, "LOL0", doc => {
            //console.log(JSON.stringify(doc.strokes));
            //console.log(JSON.stringify(change));
            //console.log("start");
            var p = doc.strokes[change.identifier].points;
            change.point.forEach(x => p.push(x));
            // console.log("end");
          });
        } else if (type === "ADD_STROKE") {
           var nDoc = Automerge.change(cheekyGlobalVariable, "LOL1", doc => {
            doc.strokes[change.identifier] = change.stroke;
          });
        } else if (type === "CLEAR_CANVAS") {
          var nDoc = Automerge.change(cheekyGlobalVariable, "LOL2", doc => {
            doc.strokes = {};
          })
        }
        var retValue = [JSON.stringify(nDoc.strokes), JSON.stringify(Automerge.getChanges(cheekyGlobalVariable, nDoc))];
        cheekyGlobalVariable = nDoc;
        return retValue;
    }

    // If we are sending/receiving changes, use this.
    // May be an issue as it's only one change ? But give it a go
    static mergeIncomingChanges(changesString) {
       let changes = JSON.parse(changesString);
       cheekyGlobalVariable = Automerge.applyChanges(cheekyGlobalVariable, changes);
       return JSON.stringify(cheekyGlobalVariables.strokes);
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
