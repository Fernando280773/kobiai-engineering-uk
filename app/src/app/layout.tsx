import type { Metadata } from "next";
import "./globals.css";


export const metadata: Metadata = {
  title: "KobiAI",
  description: "KobiAI Business OS — first slice",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
      </body>
    </html>
  );
}
