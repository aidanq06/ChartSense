import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { Pool } from 'pg';
import { randomBytes } from 'node:crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const ACCESS_TTL_SECONDS = Number(process.env.ACCESS_TOKEN_TTL_SECONDS || 3600); // 1h
const REFRESH_TTL_DAYS = Number(process.env.REFRESH_TOKEN_TTL_DAYS || 30);
const BCRYPT_ROUNDS = Number(process.env.BCRYPT_ROUNDS || 12);

export type JwtClaims = { sub: string; iat: number; exp: number };

export function signAccessToken(userId: string): string {
  return jwt.sign({ sub: userId }, JWT_SECRET, { algorithm: 'HS256', expiresIn: ACCESS_TTL_SECONDS });
}

export function verifyAccessToken(token: string): JwtClaims | null {
  try {
    return jwt.verify(token, JWT_SECRET) as JwtClaims;
  } catch {
    return null;
  }
}

export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, BCRYPT_ROUNDS);
}

export async function verifyPassword(hash: string, plain: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export function generateRefreshToken(): string {
  return randomBytes(48).toString('hex');
}

export async function createSession(pool: Pool, userId: string, refreshToken: string): Promise<string> {
  const hash = await bcrypt.hash(refreshToken, BCRYPT_ROUNDS);
  const expiresAt = new Date(Date.now() + REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);
  const { rows } = await pool.query(
    'insert into auth_sessions (user_id, refresh_token_hash, expires_at) values ($1, $2, $3) returning id',
    [userId, hash, expiresAt]
  );
  return rows[0].id as string;
}

export async function revokeSessionByToken(pool: Pool, userId: string, refreshToken: string) {
  const { rows } = await pool.query('select id, refresh_token_hash from auth_sessions where user_id = $1 and revoked_at is null and expires_at > now()', [userId]);
  for (const r of rows) {
    const match = await bcrypt.compare(refreshToken, r.refresh_token_hash as string);
    if (match) {
      await pool.query('update auth_sessions set revoked_at = now() where id = $1', [r.id]);
      return true;
    }
  }
  return false;
}

export async function findUserIdByRefreshToken(pool: Pool, refreshToken: string): Promise<string | null> {
  const { rows } = await pool.query('select id, user_id, refresh_token_hash from auth_sessions where revoked_at is null and expires_at > now()');
  for (const r of rows) {
    const match = await bcrypt.compare(refreshToken, r.refresh_token_hash as string);
    if (match) return r.user_id as string;
  }
  return null;
}


