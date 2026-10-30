import Image from "next/image";
import { CopyCommand } from "@/components/CopyCommand";
import { ThemeBands, ThemeDots } from "@/components/ThemePicker";
import { coffeeUrl, dmgUrl, repoUrl, version } from "@/lib/site";
import { THEMES } from "@/lib/themes";

const features = [
  ["A heads-up before every break", "A card appears 30 seconds ahead. Start now, or push the break back 1, 5 or 15 minutes. A small countdown follows your cursor so nothing catches you off guard."],
  ["Strict or relaxed, your call", "Casual lets you skip any time. Balanced unlocks Skip after five seconds. Hardcore takes the button away. Set a daily snooze limit and choose what pressing Esc twice does."],
  ["Quiet during calls", "If your microphone or camera is on, Gazewell skips the break instead of interrupting. It also holds off during screen recordings, video playback and fullscreen apps."],
  ["Waits for you to stop typing", "A break never lands mid-sentence. And if you step away from the keyboard for as long as a break lasts, the timer starts over."],
  ["Your hours, your schedule", "Limit reminders to office hours and days. Add fixed breaks like lunch, and a longer break every few rounds."],
  ["Reminders that fill the screen", "Posture, blinking, water and stretching each get a full-screen animation in your theme, and clicks and typing pass straight through."],
  ["Make it yours", "Seven themes, a font for the title, subtitle and countdown, your own messages, sounds and break-screen backgrounds."],
  ["See how it's going", "Breaks taken, skipped and snoozed today, a seven-day chart and your streak."],
  ["Keys and automation", "Global shortcuts start, skip or pause breaks from any app. A Shortcut or AppleScript can run when a break starts or ends."],
];

const reminders = [
  ["reminder-water", "Hydration", "Water falls across the whole screen."],
  ["reminder-posture", "Posture", "Chevrons rise and fade as you sit taller."],
  ["reminder-blink", "Blink", "Slow eyelids close and open over the screen."],
  ["reminder-stretch", "Stretch", "Silk ribbons widen like a long stretch."],
];

const faq = [
  ["Is Gazewell free?", "Yes. The source code is public on GitHub, and if it helps you, you can buy me a coffee."],
  ["Does it connect to the internet?", "No. Gazewell makes no network connections, has no account and no analytics. Your settings and stats stay on your Mac."],
  ["Which Macs does it run on?", "macOS 13 or later, on Apple silicon and Intel."],
  ["Why does macOS say it can't verify Gazewell?", "The app isn't notarized by Apple yet. On first launch, open System Settings, choose Privacy & Security and click Open Anyway. You only do this once."],
  ["Will it interrupt my calls?", "No. While your microphone or camera is in use, a due break is skipped and the timer starts over. If you'd rather delay it until the call ends, there's a setting for that."],
  ["Does it work with more than one display?", "Yes. Breaks and reminders cover every connected display."],
  ["How do I remove it?", "Quit Gazewell from the menu bar and drag it out of Applications, or run brew uninstall --cask gazewell."],
];

const h2 = "font-display text-[clamp(2rem,4.6vw,3.3rem)] leading-[1.1] tracking-tight";

export default function Home() {
  return (
    <>
      <header className="sticky top-0 z-50 border-b border-ink/10 bg-bg/85 backdrop-blur-md">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-6 px-6 py-4">
        <a href="#" className="font-display text-2xl font-semibold tracking-tight">Gazewell</a>
        <nav aria-label="Main" className="hidden items-center gap-8 text-[0.95rem] md:flex">
          <a className="hover:underline" href="#themes">Themes</a>
          <a className="hover:underline" href="#features">Features</a>
          <a className="hover:underline" href="#install">Install</a>
          <a className="hover:underline" href={repoUrl}>GitHub</a>
        </nav>
        <div className="flex items-center gap-4">
          <ThemeDots />
          <a
            href={coffeeUrl}
            aria-label="Buy me a coffee"
            className="inline-flex items-center gap-2 rounded-full border border-ink/35 px-3 py-2 text-[0.9rem] font-semibold transition-colors hover:bg-ink/10 sm:px-4"
          >
            <svg aria-hidden viewBox="0 0 24 24" className="h-[18px] w-[18px]" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 9h11v5a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5V9Z" />
              <path d="M16 10.5h1.5a2.5 2.5 0 0 1 0 5H15.5" />
              <path d="M8.5 3.5c0 1.2-1 1.3-1 2.5M12 3.5c0 1.2-1 1.3-1 2.5" />
            </svg>
            <span className="hidden sm:inline">Buy me a coffee</span>
          </a>
        </div>
        </div>
      </header>

      <main>
        <section className="mx-auto w-full max-w-6xl px-6 pb-12 pt-16 md:pt-24">
          <h1 className="font-display max-w-[17ch] text-[clamp(2.7rem,7.2vw,5.75rem)] font-semibold leading-[1.02] tracking-tight">
            Every 20 minutes, look 20 feet away for 20 seconds.
          </h1>
          <p className="mt-7 max-w-[54ch] text-xl text-ink/80">
            Gazewell lives in your Mac&apos;s menu bar and gives your eyes the break they need. It waits for a pause in your typing and stays out of your calls.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-4">
            <a className="btn btn-primary" href={dmgUrl}>Download for macOS</a>
            <a className="btn btn-ghost" href="#install">Install with Homebrew</a>
          </div>
          <p className="mt-5 text-[0.95rem] text-ink/70">
            Free. Version {version} for macOS 13 or later, on Apple silicon and Intel.
          </p>
        </section>

        <section className="mx-auto w-full max-w-6xl px-6">
          <figure
            role="img"
            aria-label="Gazewell's break screen in the theme you have chosen"
            className="relative aspect-[16/10] overflow-hidden rounded-[28px] border border-ink/20 shadow-2xl shadow-black/30"
          >
            {THEMES.map((t, i) => (
              <Image
                key={t.id}
                src={`/images/break-${t.id}.jpg`}
                alt=""
                width={1600}
                height={1000}
                priority={i === 0}
                className={`shot shot-${t.id} absolute inset-0 h-full w-full object-cover`}
              />
            ))}
          </figure>
        </section>

        <section id="themes" className="mx-auto w-full max-w-6xl scroll-mt-24 px-6 py-24 md:py-32">
          <h2 className={`${h2} max-w-[20ch]`}>Seven themes. Pick one and this whole page changes.</h2>
          <p className="mt-5 max-w-[56ch] text-lg text-ink/80">
            Each theme recolours the app and plays its own scene on the break screen: a tree that grows, stones that stack, water that rises.
          </p>
          <div className="mt-10">
            <ThemeBands />
          </div>
        </section>

        <section id="features" className="mx-auto w-full max-w-6xl scroll-mt-24 px-6 pb-24 md:pb-32">
          <h2 className={`${h2} max-w-[18ch]`}>Built to stay out of your way</h2>
          <dl className="mt-12">
            {features.map(([title, body]) => (
              <div key={title} className="grid gap-2 border-t border-ink/15 py-7 md:grid-cols-[minmax(0,19rem)_1fr] md:gap-12">
                <dt className="font-display text-2xl font-semibold leading-snug">{title}</dt>
                <dd className="max-w-[62ch] text-ink/80">{body}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section className="mx-auto w-full max-w-6xl px-6 pb-24 md:pb-32">
          <h2 className={`${h2} max-w-[20ch]`}>Four reminders that fill the screen</h2>
          <p className="mt-5 max-w-[56ch] text-lg text-ink/80">
            Posture, blinking, water and stretching nudge you for a few seconds, then fade away. They never block what you are doing.
          </p>
          <div className="mt-10 grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-4">
            {reminders.map(([file, name, caption]) => (
              <figure key={file}>
                <Image src={`/images/${file}.jpg`} alt={`${name} reminder`} width={720} height={450} className="w-full rounded-2xl border border-ink/15" />
                <figcaption className="mt-3">
                  <span className="font-display text-lg font-semibold">{name}</span>
                  <span className="block text-[0.95rem] text-ink/75">{caption}</span>
                </figcaption>
              </figure>
            ))}
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-6 pb-24 md:pb-32">
          <h2 className={`${h2} max-w-[20ch]`}>Everything lives in the menu bar</h2>
          <div className="mt-10 grid items-start gap-8 md:grid-cols-[1.6fr_1fr]">
            <figure>
              <Image src="/images/settings.jpg" alt="Gazewell settings with a toolbar of tabs and the theme picker" width={1000} height={864} className="w-full rounded-2xl border border-ink/15" />
              <figcaption className="mt-3 text-[0.95rem] text-ink/75">Settings: a tab for every part of the app, and one switch to turn Gazewell off.</figcaption>
            </figure>
            <div className="grid gap-8">
              <figure>
                <Image src="/images/menu.jpg" alt="The menu bar popover with the countdown to your next break" width={520} height={618} className="w-full max-w-[19rem] rounded-2xl border border-ink/15" />
                <figcaption className="mt-3 text-[0.95rem] text-ink/75">The menu: time to your next break, start, skip or pause.</figcaption>
              </figure>
              <figure>
                <Image src="/images/headsup.png" alt="The heads-up card shown before a break" width={760} height={289} className="w-full rounded-2xl border border-ink/15" />
                <figcaption className="mt-3 text-[0.95rem] text-ink/75">The heads-up card, 30 seconds before a break.</figcaption>
              </figure>
            </div>
          </div>
        </section>

        <section id="install" className="mx-auto w-full max-w-6xl scroll-mt-24 px-6 pb-24 md:pb-32">
          <h2 className={h2}>Get Gazewell</h2>
          <div className="mt-10 grid gap-10 md:grid-cols-2 md:gap-14">
            <div>
              <h3 className="font-display text-2xl font-semibold">With Homebrew</h3>
              <div className="mt-4">
                <CopyCommand lines={["brew tap dhri-yama/tap", "brew trust dhri-yama/tap", "brew install --cask gazewell"]} />
              </div>
              <p className="mt-3 text-[0.95rem] text-ink/75">Recent versions of Homebrew ask you to trust a third-party tap before installing from it.</p>
            </div>
            <div>
              <h3 className="font-display text-2xl font-semibold">As a download</h3>
              <p className="mt-4 max-w-[46ch] text-ink/80">Open the disk image and drag Gazewell to your Applications folder.</p>
              <a className="btn btn-primary mt-5" href={dmgUrl}>Download Gazewell {version}</a>
              <p className="mt-3 text-[0.95rem] text-ink/75">
                See <a className="underline" href={`${repoUrl}/releases`}>all releases</a> and the <a className="underline" href={`${repoUrl}/blob/main/CHANGELOG.md`}>changelog</a>.
              </p>
            </div>
          </div>
          <div className="mt-10 max-w-[70ch] rounded-2xl border border-ink/15 bg-ink/[0.06] p-6 backdrop-blur">
            <h3 className="font-display text-xl font-semibold">The first time you open it</h3>
            <p className="mt-2 text-ink/80">
              Gazewell isn&apos;t notarized by Apple yet, so macOS may stop it at first launch. Open System Settings, choose Privacy &amp; Security and click Open Anyway. After that it opens like any other app.
            </p>
          </div>
        </section>

        <section id="faq" className="mx-auto w-full max-w-6xl scroll-mt-24 px-6 pb-24 md:pb-32">
          <h2 className={h2}>Questions</h2>
          <div className="mt-10 max-w-3xl border-b border-ink/15">
            {faq.map(([q, a]) => (
              <details key={q} className="group border-t border-ink/15 py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-6 font-display text-xl font-semibold [&::-webkit-details-marker]:hidden">
                  {q}
                  <span aria-hidden className="text-3xl font-light leading-none transition-transform group-open:rotate-45">+</span>
                </summary>
                <p className="mt-3 max-w-[62ch] text-ink/80">{a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>

      <footer className="mx-auto w-full max-w-6xl border-t border-ink/15 px-6 py-10">
        <div className="flex flex-wrap items-start justify-between gap-8">
          <div>
            <p className="font-display text-2xl font-semibold">Gazewell</p>
            <p className="mt-2 max-w-[44ch] text-[0.95rem] text-ink/70">
              An independent project, not affiliated with any other break-reminder app.
            </p>
          </div>
          <ul className="flex flex-wrap gap-x-8 gap-y-2 text-[0.95rem]">
            <li><a className="hover:underline" href={repoUrl}>GitHub</a></li>
            <li><a className="hover:underline" href={`${repoUrl}/releases`}>Releases</a></li>
            <li><a className="hover:underline" href={`${repoUrl}/blob/main/CHANGELOG.md`}>Changelog</a></li>
            <li><a className="hover:underline" href={coffeeUrl}>Buy me a coffee</a></li>
          </ul>
        </div>
      </footer>
    </>
  );
}
