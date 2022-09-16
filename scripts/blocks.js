Array.prototype.max = function () {
    return Math.max.apply(null, this)
}

var possibleScores

function morePossible(n) {
    var new_possible_scores = []
    new_possible_scores = new_possible_scores.concat(possibleScores)
    //for (var p=0; p<(n - 3); p++) {
    for (var i = 0; i < possibleScores.length; i++) {
        var current = []

        current = current.concat(possibleScores[i])
        var current2 = []
        current2 = current2.concat(possibleScores[i])
        current.push(1)
        current2.push(2)
        new_possible_scores.push(current)
        new_possible_scores.push(current2)
    }
    //console.log(new_possible_scores);
    //   }
    possibleScores = new_possible_scores
}

function generatePossibleScores(n, _s) {
    var combos = possibleScores
    var smallestCombo = 999989
    for (var p = 0; p < combos.length; p++) {
        if (scorePossibleArrayComparator(_s, combos[p])) {
            //console.log("valid combo", combos[p])
            if (combos[p].length < smallestCombo) {
                smallestCombo = combos[p].length
            }
        } else {

        }
    }

    return smallestCombo
}

function isScorePossible(scoreVal, scoreArray) {
    var runningTotal = 0
    var currentVal = 0
    currentVal = scoreVal
    //if (scoreVal == runningTotal) { return true; }
    for (var i = 0; i < scoreArray.length; i++) {
        runningTotal += scoreArray[i]
        if (scoreVal == runningTotal) {
            return true
        }
    }
    if (runningTotal < scoreVal) {
        return false
    }
    if (runningTotal > scoreVal) {
        return true
    }

    return false
}
function scorePossibleArrayComparator(allScores, scoreArray) {
    var rv = true
    for (var i = 0; i < allScores.length; i++) {
        if (!isScorePossible(allScores[i], scoreArray)) {
            return false
        }
        if (!canScoreBeMadeFromPartOfArray(allScores[i], scoreArray)) {
            return false
        }

        //}
    }
    return rv
}
function canScoreBeMadeFromPartOfArray(as, sa) {
    // console.log("Checking for subset validity", as, sa);
    var teamScore = as
    var arrayToCheck = sa
    var arrayRefCounts = new Map()

    var ss = subsetSum(arrayToCheck, arrayToCheck.length, teamScore)

    if (ss > 0) {
        return true
    }

    return false
}

function subsetSum(a, n, sum) {

    var tab = new Array(n + 1)
    for (var i = 0; i < n + 1; i++)
        tab[i] = new Array(sum + 1)

    tab[0][0] = 1
    for (var i = 1; i <= sum; i++)
        tab[0][i] = 0

    for (var i = 1; i <= n; i++) {
        for (var j = 0; j <= sum; j++) {

            if (a[i - 1] > j)
                tab[i][j] = tab[i - 1][j]
            else {
                tab[i][j] = tab[i - 1][j] + tab[i - 1][j - a[i - 1]]
            }
        }
    }

    return tab[n][sum]
}
