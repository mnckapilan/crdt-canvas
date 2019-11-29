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
    console.log("our id" + change.identifier)
    console.log("automerg id" + Automerge.getObjectId())
    var type = change.type;
    if (type === "ADD_POINT") {
      var nDoc = Automerge.change(cheekyGlobalVariable, "ADD_POINT", doc => {
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

  static mergeIncomingChanges(changesString) {
    let changes = JSON.parse(changesString);
    cheekyGlobalVariable = Automerge.applyChanges(cheekyGlobalVariable, changes);
    return JSON.stringify(cheekyGlobalVariable.strokes);
  }

  static getAllChanges() {
    let q = Automerge.getChanges(Automerge.init(), cheekyGlobalVariable);
    let p = JSON.stringify(q);
    return p;
  }
};
