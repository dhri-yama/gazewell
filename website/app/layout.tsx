import type { Metadata } from "next";
import { DM_Sans, Fraunces, Nunito } from "next/font/google";
import "./globals.css";

const dm = DM_Sans({ subsets: ["latin"], variable: "--font-dm", display: "swap" });
const fraunces = Fraunces({ subsets: ["latin"], variable: "--font-fraunces", display: "swap" });
const nunito = Nunito({ subsets: ["latin"], variable: "--font-nunito", display: "swap" });

export const metadata: Metadata = {
  title: "Gazewell: eye-break reminders for your Mac",
  description:
    "Gazewell is a macOS menu bar app that reminds you to rest your eyes. It waits for a pause in your typing, stays quiet during calls and comes in seven themes.",
  openGraph: {
    title: "Gazewell: eye-break reminders for your Mac",
    description: "Look away every 20 minutes. A menu bar app that stays out of your way.",
    type: "website",
  },
};

// Runs before first paint so a saved theme never flashes the default one.
const initTheme = `(function(){try{var t=localStorage.getItem("gazewell-theme");if(/^(forest|earth|ocean|air|night|medito|mono)$/.test(t))document.documentElement.dataset.theme=t}catch(e){}})();`;

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" data-theme="forest" suppressHydrationWarning className={`${dm.variable} ${fraunces.variable} ${nunito.variable}`}>
      <body>
        <script dangerouslySetInnerHTML={{ __html: initTheme }} />
        {children}
      </body>
    </html>
  );
}
