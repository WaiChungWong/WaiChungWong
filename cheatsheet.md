<details open="open">
  <summary>Table of contents</summary>
  <ul>
    <li>
      <a href="#git">Git</a>
      <ul>
        <li>
          <a href="#remove-all-history">Remove All History</a>
        </li>
      </ul>
    </li>
    <li>
      <a href="#regular-expressions">Regular Expressions</a>
      <ul>        
        <li>
          <a href="#validations">Validations</a>
          <ul>
            <li>
              <a href="#number-ranges">Number ranges</a>
            </li>
            <li>
              <a href="#hex-color-code">Hex color code</a>
            </li>
          </ul>
        </li>
      </li>
    </ul>
  </ul>
</details>

# Git

## Remove All History

- example: Remove all history in the main branch

  ```bash
  # 1. Rename the target branch.
  git branch -m old-main

  # 2. Create a new branch with the original name.
  git checkout --orphan main

  # 2. Add all the files to the newly created branch.
  git add .

  # 3. Create the first commit.
  git commit -m "First commit"

  # 4. Force push the current branch and set the remote as upstream.
  git push --set-upstream --force origin main

  # 5. Delete the original branch (optional).
  git branch -D old-main
  ```

# Regular Expressions

## Validations

### Number ranges

- example 1: `150-193` = `(150-189, 190-193)`

  ```json
  1([5-8][0-9]|9[0-3])
  ```

- example 2: `256-512` = `(256-259, 260-299, 300-499, 500-509,510-512)`

  ```json
  (25[6-9]|2[6-9][0-9]|[3-4][0-9][0-9]|50[0-9]|51[0-2])
  ```

### Hex color code

- Hex code = `#000-#fff, #000000-#ffffff`
  ```json
  #([a-fA-F0-9]{6}|[a-fA-F0-9]{3})
  ```
