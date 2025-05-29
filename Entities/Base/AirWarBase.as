// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;
	this.CreateRespawnPoint("base", Vec2f(0.0f, 16.0f));
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);

	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.addCommandID("change class");

	this.Tag("change class drop inventory");

	this.getSprite().SetZ(-50.0f);   // push to background

	// minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 29, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);
}

void onTick(CBlob@ this)
{

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	/*
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		if (isInRadius(this, caller))
		{
			BuildRespawnMenuFor(this, caller);
		}
		else
		{
			CBitStream params;
			caller.CreateGenericButton("$change_class$", Vec2f(0, 0), this, buildSpawnMenu, getTranslatedString("Change class"));
		}
	}
*/
	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.getRadius();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//only collide with projectiles
	if (blob.hasTag("projectile") && this.getTeamNum() != blob.getTeamNum())
	{
		return true;
	}

	return false;
}