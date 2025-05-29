#include "Hitters.as"
#include "GenericButtonCommon.as"

const u32 VANISH_BODY_SECS = 45;
const f32 CARRIED_BLOB_VEL_SCALE = 1.0;
const f32 MEDIUM_CARRIED_BLOB_VEL_SCALE = 0.8;
const f32 HEAVY_CARRIED_BLOB_VEL_SCALE = 0.6;


void onInit(CBlob@ this)
{
	this.set_f32("hit dmg modifier", 0.0f);
	this.set_f32("hit dmg modifier", 0.0f);
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.set_u32("death time", getGameTime());

		this.UnsetMinimapVars(); //remove minimap icon

		// we want the corpse to stay but player to respawn so we force a die event in rules

		if (getNet().isServer())
		{
			if (this.getPlayer() !is null)
			{
				getRules().server_PlayerDie(this.getPlayer());
				this.server_SetPlayer(null);
			}
			else
			{
				getRules().server_BlobDie(this);
			}
		}

		// sound

		if (this.getSprite() !is null) //moved here to prevent other logic potentially not getting run
		{
			f32 gibHealth = this.get_f32("gib health");

			if (this !is hitterBlob || customData == Hitters::fall)
			{
				this.getSprite().PlaySound("Bomb.ogg");
			}

			// turn off bow sound (emit sound)
			this.getSprite().SetEmitSoundPaused(true);
		}

		this.getCurrentScript().tickFrequency = 30;

		this.set_f32("hit dmg modifier", 0.5f);

		// new physics vars so bodies don't slide
		//this.getShape().setFriction(0.75f);
		//this.getShape().setElasticity(0.2f);

		// disable tags
		this.Untag("player");
		this.Tag("dead player");
		this.getShape().getVars().isladder = false;
		this.getShape().getVars().onladder = false;
		this.getShape().checkCollisionsAgain = true;
		this.getShape().SetGravityScale(1.0f);
        // fall out of attachments/seats // drop all held things
		this.server_DetachAll();
	}
	else
	{
		this.set_u32("death time", getGameTime());
	}

	return damage;
}


bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	// can't be put in player inventory.
	return inventoryBlob.getPlayer() is null;
}

void onTick(CBlob@ this)
{
	this.server_Hit(this, this.getPosition(), Vec2f(), 1.0f, Hitters::crush);
	
	//die if we've "expired"
	if (this.get_u32("death time") + VANISH_BODY_SECS * getTicksASecond() < getGameTime())
	{
		this.server_Die();
	}
}

// reset vanish counter on pickup
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (this.hasTag("dead") && this.getInventory().getItemsCount() > 0 && canSeeButtons(this, forBlob));
}