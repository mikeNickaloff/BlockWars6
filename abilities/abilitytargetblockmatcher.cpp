#include "abilitytargetcomponent.h"
#include "abilitytargetblockmatcher.h"
#include "../src/gameengine.h"

AbilityTargetBlockMatcher::AbilityTargetBlockMatcher(QObject *parent, GameEngine* i_engine)
    : AbilityTargetComponent{parent, i_engine}
{

}
