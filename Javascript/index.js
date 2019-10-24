import * as Automerge from 'automerge'

var cheekyGlobalVariable = Automerge.load('["~#iL",[["~#iM",["ops",["^0",[["^1",["action","makeMap","obj","5a65b71d-f303-46b7-9052-67dc8ee533e0"]],["^1",["action","link","obj","00000000-0000-0000-0000-000000000000","key","strokes","value","5a65b71d-f303-46b7-9052-67dc8ee533e0"]]]],"actor","92d0a138-8f2b-4aa1-819c-c8695d8f5f2d","seq",1,"deps",["^1",[]],"message","Initialization"]]]]');

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
          });
        } else if (type === "UNDO_CHANGE") {
          var nDoc = Automerge.canUndo(doc) ? Automerge.undo(doc) : doc;
        } else if (type === "REDO_CHANGE") {
          var nDoc = Automerge.canRedo(doc) ? Automerge.redo(doc) : doc;
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
       return JSON.stringify(cheekyGlobalVariable.strokes);
     }

     // If we are sending/receiving changes, use this.
    // May be an issue as it's only one change ? But give it a go
    static getAllChanges() {
      let q = Automerge.getChanges(Automerge.init(), cheekyGlobalVariable);
      let p = JSON.stringify(q);
      return p;
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
