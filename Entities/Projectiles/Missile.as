
#include "Hitters.as";
#include "MakeDustParticle.as";

//Bullet logic

//blob functions
void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");
	this.Tag("homing");
	this.sendonlyvisible = false;

	this.getSprite().SetEmitSound("FireRoar.ogg");
    this.getSprite().SetEmitSoundPaused(false);

	this.SetMapEdgeFlags(CBlob::map_collide_none);

	this.server_SetTimeToDie(5);

	this.set_f32("explosive_radius", 16.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_f32("map_damage_radius", 16.0f);
	this.set_f32("map_damage_ratio", 0.1f);
	this.set_bool("map_damage_raycast", true);
	this.Tag("exploding");
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();

	f32 angle;
	bool processSticking = true;
	if (!this.hasTag("collided")) //we haven't hit anything yet!
	{
		Vec2f pos = this.getPosition();

		Vec2f velocity = this.getVelocity();
		angle = (velocity).Angle();

		// follow enemy

		CBlob@ enemy = null;
		u16 target = this.get_netid("target");	// need to devide it because of console
		if (target != 0xFFFF) @enemy = getBlobByNetworkID(target);

		if (enemy !is null && !enemy.hasTag("dead"))
		{
			Vec2f aim = enemy.getPosition();
			Vec2f aimedDirection = aim - pos;
			f32 aimAngle = aimedDirection.Angle();

			f32 dif = aimAngle - angle;

			while (dif > 180.0f)
			{
				dif -= 360.0f;
			}
			while (dif < -180.0f)
			{
				dif += 360.0f;
			}

			float homingPower = 3.0f;

			if (this.hasTag("ECM")) homingPower * 0.66f;
			if (this.hasTag("ESM")) homingPower * 1.5f;

			if (dif >= 0.0f)
			{
				dif = Maths::Min(dif, homingPower);
			}
			else
			{
				dif = Maths::Max(dif, -homingPower);
			}

			this.setVelocity(velocity.RotateBy(-dif));
		}
		Pierce(this);   //map
		this.setAngleDegrees(-angle);

		velocity.Normalize();

		this.AddForce(velocity * (this.hasTag("ESM") ? 0.75f : 0.5f));

		if (isClient())
		{
			// smoke effect
			MakeDustParticle(pos + Vec2f(0.0f, 8.0f), "SmallSmoke?.png");
			// fire particle
			SColor color = SColor(0xff, 0xdb, 0x57, 0x43);
			f32 randomInn = -10.0f + ((f32(XORRandom(256)) / 256.0f) * 20.0f);
			CParticle@ p = ParticlePixelUnlimited(this.getPosition(), Vec2f(-5.0f, 0.0f).RotateBy(this.getAngleDegrees() + randomInn), color, true);
			if(p !is null)
			{
			    p.collides = false;
			    p.gravity = Vec2f_zero;
			    p.Z = -2.0f;
			    p.timeout = 10;
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if ((blob is null || (blob !is null && doesCollideWithBlob(this, blob))) && !this.hasTag("collided"))
	{
		//perform the hit and tag so that another doesn't happen
		if (blob !is null) this.server_Hit(blob, point1, this.getOldVelocity(), this.hasTag("ESM") ? 2.5f : 2.0f, Hitters::arrow);
		this.Tag("collided");
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//don't collide with other projectiles
	if (blob.hasTag("projectile"))
	{
		return false;
	}

	//collide so normal arrows can be ignited
	if (blob.getName() == "fireplace")
	{
		return true;
	}

	bool check =	this.getTeamNum() != blob.getTeamNum() || // collide with enemy blobs
					blob.getName() == "bridge" ||
					(blob.getName() == "keg" && !blob.isAttached() && this.hasTag("fire source")); // fire arrows collide with team kegs that arent held

	//maybe collide with team structures
	if (!check)
	{
		CShape@ shape = blob.getShape();
		//check = (shape.isStatic() && !shape.getConsts().platform);
	}

	if (check)
	{
		if (
			//we've collided
			this.getShape().isStatic() ||
			this.hasTag("collided") ||
			//or they're dead
			blob.hasTag("dead") ||
			//or they ignore us
			blob.hasTag("ignore_arrow")
		) {
			return false;
		}
		else
		{
			return true;
		}
	}

	return false;
}

void Pierce(CBlob @this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();

	if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
	{
		this.server_Die();
		this.Tag("collided");
	}
}