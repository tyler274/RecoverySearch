/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Emit a self-contained server bundle (.next/standalone) so the Docker
  // runtime image can run `node server.js` without node_modules.
  output: "standalone",
};

export default nextConfig;
