import * as Automerge from 'automerge'
import * as Y from 'yjs'

export class Automerger {

  static randomNumber() {
    // console.log("random number generated");
    return Math.floor(Math.random() * 100);
  }

  static initDocument() {
    const doc = new Y.Doc();
    // return Y.encodeStateAsUpdate(doc);
    console.log(Y.encodeStateAsUpdate(doc));
  }

  // Local changes when user adds a stoke.
  // We will be sending a list of changes but this list only contains one change

  static addChange(changeString) {
    var change = JSON.parse(changeString);
    var type = change.type;
    if (type === "ADD_POINT") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "ADD_POINT", doc => {
        //console.log(JSON.stringify(doc.strokes));
        //console.log(JSON.stringify(change));
        //console.log("start");
        var p = doc.strokes[change.identifier].points;
        change.point.forEach(x => p.push(x));
        doc.strokes[change.identifier].segments[0].end += change.point.length;
        // console.log("end");
      });
    } else if (type === "ADD_STROKE") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "ADD_STROKE", doc => {
        doc.strokes[change.identifier] = change.stroke;
      });
    } else if (type === "CLEAR_CANVAS") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "CLEAR_CANVAS", doc => {
        doc.strokes = {};
      });
    } else if (type === "REMOVE_STROKE") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "REMOVE_STROKE", doc => {
        var stroke = doc.strokes[change.identifier];
        var index = change.index;
        if (stroke.segments.length == 1) {
          delete doc.strokes[change.identifier];
        } else {
          for (var j = 0; j < stroke.segments.length; j++) {
            var segment = stroke.segments[j];
            if (segment.start <= index && index <= segment.end) {
              stroke.segments.splice(j, 1);
              break;
            }
          }
        }
      });
    } else if (type === "PARTIAL_REMOVE_STROKE") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "PARTIAL_REMOVE_STROKE", doc => {
        var stroke = doc.strokes[change.identifier];
        var index = change.index;
        for (var j = 0; j < stroke.segments.length; j++) {
          var segment = stroke.segments[j];
          if (segment.start <= index && index <= segment.end) {
            if (index + 1 < segment.end) {
              stroke.segments.push({
                start: index + 1,
                end: segment.end
              });
            }

            if (segment.start < index - 1) {
              segment.end = index - 1;
            } else {
              stroke.segments.splice(j, 1);
              j--;
            }
          }
        }
      });
    } else if (type === "BETTER_PARTIAL") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "BETTER_PARTIAL", doc => {
        var stroke = doc.strokes[change.identifier];
        var lower = change.lower;
        var upper = change.upper;
        var end = stroke.segments.length;
        for (var j = 0; j < end; j++) {
          var segment = stroke.segments[j];

          if (segment.start <= lower && lower <= segment.end) {
            if (segment.start <= upper && upper <= segment.end) {
              stroke.segments.push({
                start: upper,
                end: segment.end
              });
            }
            segment.end = lower;
          } else if (segment.start <= upper && upper <= segment.end) {
            segment.start = upper;
          } else if (lower <= segment.start && segment.end <= upper) {
            stroke.segments.splice(j, 1);
            j--;
            end--;
          }
        }
      });
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
