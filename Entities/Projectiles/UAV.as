
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

	this.set_u8("cooldown", 30);
	this.addCommandID("shoot");
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

			// shoot PLSL
			if (isServer() && this.get_u8("cooldown") <= 0 && aimedDirection.getLength() <= 200.0f)
			{
				CBlob@ missile = server_CreateBlobNoInit("plsl");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition());
					missile.setVelocity(Vec2f(50.0f, 0.0f).RotateBy(-aimAngle));

					this.SendCommand(this.getCommandID("shoot"));
				}

				this.set_u8("cooldown", 13);
			}

			f32 dif = aimAngle - angle;

			while (dif > 180.0f)
			{
				dif -= 360.0f;
			}
			while (dif < -180.0f)
			{
				dif += 360.0f;
			}

			float homingPower = 5.0f;


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

		if (this.get_u8("cooldown") > 0) this.sub_u8("cooldown", 1);
		Pierce(this);   //map
		this.setAngleDegrees(-angle);

		velocity.Normalize();

		this.AddForce(velocity * 0.2f);

		// smoke effect
		MakeDustParticle(pos + Vec2f(0.0f, 8.0f), "SmallSmoke?.png");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot") && isClient()) Sound::Play("ProduceSound.ogg", this.getPosition());
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