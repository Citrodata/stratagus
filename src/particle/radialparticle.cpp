//       _________ __                 __
//      /   _____//  |_____________ _/  |______     ____  __ __  ______
//      \_____  \\   __\_  __ \__  \\   __\__  \   / ___\|  |  \/  ___/
//      /        \|  |  |  | \// __ \|  |  / __ \_/ /_/  >  |  /\___ |
//     /_______  /|__|  |__|  (____  /__| (____  /\___  /|____//____  >
//             \/                  \/          \//_____/            \/
//  ______________________                           ______________________
//                        T H E   W A R   B E G I N S
//         Stratagus - A free fantasy real time strategy game engine
//
/**@name radialparticle.cpp - The radial particle. */
//
//      (c) Copyright 2012 by cybermind
//
//      This program is free software; you can redistribute it and/or modify
//      it under the terms of the GNU General Public License as published by
//      the Free Software Foundation; only version 2 of the License.
//
//      This program is distributed in the hope that it will be useful,
//      but WITHOUT ANY WARRANTY; without even the implied warranty of
//      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//      GNU General Public License for more details.
//
//      You should have received a copy of the GNU General Public License
//      along with this program; if not, write to the Free Software
//      Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//      02111-1307, USA.
//

//@{

#include "particle.h"
#include "stratagus.h"

#include <cmath>

CRadialParticle::CRadialParticle(CPosition position, const GraphicAnimation &animation, int maxSpeed, int drawlevel) :
	CParticle(position, drawlevel),
	animation(animation.clone()),
	direction(MyRand() % 360),
	speed((MyRand() % maxSpeed) / 10),
	maxSpeed(maxSpeed)
{
}

bool CRadialParticle::isVisible(const CViewport &vp) const /* override */
{
	return animation && animation->isVisible(vp, pos);
}

void CRadialParticle::draw() /* override */
{
	CPosition screenPos = ParticleManager.getScreenPos(pos);
	animation->draw(static_cast<int>(screenPos.x), static_cast<int>(screenPos.y));
}

void CRadialParticle::update(int ticks) /* override */
{
	this->pos.x += this->speed * sin(this->direction);
	this->pos.y += this->speed * cos(this->direction);

	animation->update(ticks);
	if (animation->isFinished()) {
		destroy();
	}
}

CParticle *CRadialParticle::clone() const /* override */
{
	CParticle *p = new CRadialParticle(pos, *animation, maxSpeed, drawLevel);
	return p;
}

//@}
