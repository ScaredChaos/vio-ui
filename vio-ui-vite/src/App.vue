<script setup>
import { ref, computed } from 'vue'
import speichernIcon from './assets/speichern.png'
import rawCategories from './keybinds.json'

// JSON → reaktiv machen + showSaved hinzufügen
const categories = ref(
  rawCategories.map((cat) => ({
    ...cat,
    commands: cat.commands.map((cmd) => ({
      ...cmd,
      showSaved: false, // Popup-Flag
    })),
  }))
)

const selectedCategoryId = ref('persoenlich')

const selectedCategory = computed(() =>
  categories.value.find((c) => c.id === selectedCategoryId.value)
)

const onSaveClick = (cmd) => {
  console.log('Speichern geklickt für Befehl:', cmd.id, 'mit Taste:', cmd.key)

  // Nur speichern, wenn überhaupt eine Taste gewählt wurde
  if (cmd.key && window.mta && typeof window.mta.triggerEvent === 'function') {
    window.mta.triggerEvent('keybind_save_request', cmd.id, cmd.key)
  }

  cmd.showSaved = true
  setTimeout(() => {
    cmd.showSaved = false
  }, 700)
}


const onSelectKey = (cmd) => {
  console.log('Taste wählen geklickt für Befehl:', cmd.id)

  // In MTA-CEF vorhanden, im Dev-Server nicht → absichern:
  if (window.mta && typeof window.mta.triggerEvent === 'function') {
    window.mta.triggerEvent('keybind_select_request', cmd.id)
  }
}

const setKeyForCommandFromMta = (commandId, key) => {
  // passende Kategorie finden (die den Command enthält)
  const cat = categories.value.find((c) =>
    c.commands.some((cmd) => cmd.id === commandId)
  )
  if (!cat) return

  const cmd = cat.commands.find((cmd) => cmd.id === commandId)
  if (!cmd) return

  // Taste in der UI aktualisieren (optional in Großbuchstaben)
  cmd.key = (key || '').toUpperCase()
}

// Funktion global für MTA-CEF verfügbar machen
if (typeof window !== 'undefined') {
  window.mtaSetKeyForCommand = setKeyForCommandFromMta
}


</script>

<template>
  <v-app>
    <v-main>
      <div class="keybind-root">
        <div class="keybind-panel">
          <!-- Rote Tab-Leiste oben -->
          <v-tabs v-model="selectedCategoryId" class="keybind-tabs" bg-color="#c7433b" color="white" grow>
            <v-tab v-for="cat in categories" :key="cat.id" :value="cat.id">
              {{ cat.label }}
            </v-tab>
          </v-tabs>

          <v-divider class="keybind-divider" />

          <!-- Schwarzer Bereich nur für den Inhalt -->
          <v-card class="keybind-card" elevation="8">
            <v-card-text class="keybind-content">
              <div v-if="selectedCategory">
                <v-row v-for="cmd in selectedCategory.commands" :key="cmd.id" class="command-row" align="center">
                  <v-col cols="2">
                    <span class="command-label">{{ cmd.label }}</span>
                  </v-col>

                  <v-col cols="4" class="command-key-col">
                    <span class="command-key-label">Gewählte Taste:</span>
                    <span class="command-key-value">{{ cmd.key }}</span>
                  </v-col>

                  <v-col cols="4">
                    <v-btn block size="small" variant="flat" class="keybind-select-btn" @click="onSelectKey(cmd)">
                      Taste wählen
                    </v-btn>
                  </v-col>

                  <v-col cols="2" class="d-flex justify-center">
                    <div class="save-icon-container">
                      <div class="save-icon-wrapper" @click="onSaveClick(cmd)">
                        <img :src="speichernIcon" alt="Speichern" class="save-icon" />
                      </div>

                      <transition name="saved-float">
                        <div v-if="cmd.showSaved" class="saved-label">
                          Gespeichert
                        </div>
                      </transition>
                    </div>
                  </v-col>
                </v-row>
              </div>

              <div v-else>
                <em>Keine Kategorie ausgewählt.</em>
              </div>
            </v-card-text>
          </v-card>
        </div>
      </div>
    </v-main>
  </v-app>
</template>

<style scoped>
/* Tabs: Fokus-/Klick-Ränder komplett weg */
.keybind-tabs :deep(.v-tab),
.keybind-tabs :deep(.v-tab.v-btn),
.keybind-tabs :deep(.v-tab.v-btn:before),
.keybind-tabs :deep(.v-tab.v-btn:after),
.keybind-tabs :deep(.v-tab--selected),
.keybind-tabs :deep(.v-tab--selected:before),
.keybind-tabs :deep(.v-tab--selected:after),
.keybind-tabs :deep(.v-btn:focus-visible) {
  outline: none !important;
  box-shadow: none !important;
  border: 0 !important;
}

/* Tabs selbst: immer vollflächig rot, keine Schatten/Ränder */
.keybind-tabs {
  text-transform: none;
  margin: 0 !important;
  padding: 0 !important;
  border: none !important;
  box-shadow: none !important;
}

.keybind-tabs :deep(.v-slide-group__content) {
  margin: 0 !important;
}

.keybind-tabs :deep(.v-tab) {
  background-color: #c7433b !important;
  margin: 0 !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}

.keybind-tabs :deep(.v-tab--selected),
.keybind-tabs :deep(.v-tab:hover) {
  box-shadow: none !important;
  border: none !important;
}

.keybind-tabs .v-tab {
  text-transform: none;
  font-weight: 600;
  letter-spacing: 0.05em;
  font-size: 0.85rem;
}

:root {
  --vio-red: #c7433b;
}

.keybind-root {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  /* vertikal zentriert */
  justify-content: center;
  /* horizontal zentriert */
}

.keybind-panel {
  width: 600px;
  margin: 0;
  padding: 0;
  background: transparent;
  border: none;
}

.keybind-card {
  background: transparent;
  color: #ffffff;
  padding-top: 0;
  border-radius: 0;
  padding-bottom: 0 !important;
  width: 600px;
  box-shadow: none !important;
  border: none !important;
}

.keybind-select-btn {
  background-color: #3a3a3a !important;
  color: #ffffff !important;
  text-transform: none;
  font-size: 0.90rem;
  padding-top: 20px;
  padding-bottom: 20px;
  border-radius: 2px;
  box-shadow: none !important;
  transition: background-color 160ms ease, transform 120ms ease;
}

.keybind-select-btn:hover {
  background-color: #505050 !important;
  transform: translateY(-1px);
}

.keybind-select-btn:active {
  background-color: var(--vio-red) !important;
  transform: translateY(0);
}

/* Button-Overlay kontrollieren */
.keybind-select-btn :deep(.v-btn__overlay) {
  background-color: transparent !important;
}

.keybind-select-btn:active :deep(.v-btn__overlay) {
  background-color: #c7433b !important;
  opacity: 0.35 !important;
}

.save-icon-wrapper {
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  transition:
    background-color 180ms ease,
    transform 150ms ease;
}

.save-icon-wrapper:hover {
  background-color: rgba(255, 255, 255, 0.08);
  transform: scale(1.05);
}

.save-icon {
  width: 24px;
  height: 24px;
  filter: brightness(0) invert(1);
}

.save-icon-container {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* „Gespeichert“-Label */
.saved-label {
  position: absolute;
  bottom: 110%;
  left: 50%;
  transform: translateX(-50%);
  font-size: 0.75rem;
  color: #ffffff;
  pointer-events: none;
  white-space: nowrap;
}

/* Animations-Transition */
.saved-float-enter-active,
.saved-float-leave-active {
  transition: opacity 0.4s ease, transform 0.4s ease;
}

.saved-float-enter-from {
  opacity: 0;
  transform: translate(-50%, 6px);
}

.saved-float-enter-to {
  opacity: 1;
  transform: translate(-50%, -2px);
}

.saved-float-leave-from {
  opacity: 1;
  transform: translate(-50%, -2px);
}

.saved-float-leave-to {
  opacity: 0;
  transform: translate(-50%, -10px);
}

/* dezente Trennlinie */
.keybind-divider {
  opacity: 0.15;
}

.keybind-content {
  padding-top: 16px;
  padding-bottom: 0 !important;
  background: rgba(0, 0, 0, 0.82);
  /* schwarzer Bereich nur für den Inhalt */
}

/* Zeilen-Styling für die Befehlsliste */
.command-row {
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  padding-bottom: 4px;
  margin-bottom: 4px;
}

.command-label {
  font-weight: 500;
}

.command-key-col {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: flex-start;
  white-space: nowrap; /* bricht „Gewählte Taste:“ + Key nicht um */
}

.command-key-label {
  opacity: 0.7;
  font-size: 0.85rem;
}

.command-key-value {
  padding: 2px 6px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 4px;
  font-family: "Roboto Mono", monospace; /* sehr elegante Mono-Font */
  font-size: 0.85rem;
  color: #ffffffcc; /* 80 % Weiß */
}



/* Footer-Leiste unten (aktuell ungenutzt, aber sauber) */
.keybind-footer {
  border-top: 0px solid rgba(255, 255, 255, 0.08);
}
</style>

<style>
html,
body,
#app {
  height: 100%;
  margin: 0;
  padding: 0;
  background: transparent !important;
  overflow: hidden !important;
  /* Scrollbars verhindern */
}

/* Vuetify-Hintergründe entfernen, Layout aber nicht anfassen */
.v-application,
.v-application__wrap,
.v-main {
  background: transparent !important;
}
</style>
