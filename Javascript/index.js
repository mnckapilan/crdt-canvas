import * as Y from 'yjs'
// const doc = new Y.Doc();

// console.log("we are in init");
// // return Y.encodeStateAsUpdate(doc);
// const strokeMap = doc.getMap("strokes")
// console.log(Y.encodeStateAsUpdate(doc));
export class Automerger {
  // Local changes when user adds a stoke.
  // We will be sending a list of changes but this list only contains one change

  static addChange(changeString) {
    console.log("entering Add change....");
    var oldDocSV = Y.encodeStateAsUpdate(doc);
    var change = JSON.parse(changeString);
    var type = change.type;
    const strokes = doc.getMap('strokes');
    if (type === "ADD_POINT") {
      console.log("trying to add a point");
      doc.transact(() => {
        var p = strokes.get(change.identifier).points;
        change.point.forEach(x => p.push(x));
        strokes.get(change.identifier).segments[0].end += change.point.length;
        // strokes.set(change.identifier, temp);
      });
    } else if (type === "ADD_STROKE") {
      console.log("trying to add a stroke");
      doc.transact(() => {
        strokeMap.set(change.identifier, change.stroke);
      });
    } else if (type === "CLEAR_CANVAS") {
      doc.transact(() => {
        doc.getMap("strokes").forEach(x => strokes.delete(x))
      })
    }
    else if (type === "REMOVE_STROKE") {
      doc.transact(() => {
        var stroke = strokes.get(change.identifier);
        var index = change.index;
        if (stroke.segments.length == 1) {
          strokes.delete(change.identifier)
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
      doc.transact(() => {
        var stroke = strokes.get(change.identifier);
        var index = change.index;
        for (var j = 0; j < stroke.segments.length; j++) {
          var segment = stroke.segment[j];
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
      doc.transact(() => {
        var stroke = strokes.get(change.identifier)
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
    var updatedDocStateVector = Y.encodeStateVector(doc)
    var changes = Y.encodeStateAsUpdate(oldDocSV, updatedDocStateVector)
    var retValue = [JSON.stringify(doc.getMap("strokes").toJSON), JSON.stringify(changes)];
    return retValue;
  }

  // If we are sending/receiving changes, use this.
  // May be an issue as it's only one change ? But give it a go
  static mergeIncomingChanges(changesString) {
    let changes = JSON.parse(changesString);
    let diff1 = Y.encodeStateAsUpdate(doc, changes)
    Y.applyUpdate(doc, diff1)
    return JSON.stringify(doc.get('strokes'));
  }

  // If we are sending/receiving changes, use this.
  // May be an issue as it's only one change ? But give it a go
  static getAllChanges() {
    let completeDoc = Y.encodeStateAsUpdate(doc);
    return JSON.stringify(completeDoc);
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
